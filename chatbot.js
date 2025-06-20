// React's UMD build makes React available globally, so no explicit import is needed here.
const { useState, useEffect, useRef } = React; // Destructure directly from global React

// Firebase imports remain as modules from CDN
import { initializeApp } from 'https://www.gstatic.com/firebasejs/11.6.1/firebase-app.js';
import { getAuth, signInAnonymously, signInWithCustomToken, onAuthStateChanged } from 'https://www.gstatic.com/firebasejs/11.6.1/firebase-auth.js';
import { getFirestore, collection, addDoc, onSnapshot, query, doc, getDoc, updateDoc, setDoc, orderBy } from 'https://www.gstatic.com/firebasejs/11.6.1/firebase-firestore.js';

// Main App component
const App = () => {
    const [messages, setMessages] = useState([]);
    const [input, setInput] = useState('');
    const [loading, setLoading] = useState(false);
    const [db, setDb] = useState(null); // Will be null in demo mode
    const [auth, setAuth] = useState(null);
    const [userId, setUserId] = useState(null);
    const [chatSessions, setChatSessions] = useState([]);
    const [currentSessionId, setCurrentSessionId] = useState(null);
    const messagesEndRef = useRef(null);
    const [isReady, setIsReady] = useState(false); // Unified readiness state
    const [isDemoMode, setIsDemoMode] = useState(false);
    const [perceptionDocContent, setPerceptionDocContent] = useState('');

    // Scroll to the latest message whenever messages update
    useEffect(() => {
        messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
    }, [messages]);

    // Initialize Firebase and handle authentication
    useEffect(() => {
        // Check for Firebase config existence and validity
        if (typeof __firebase_config === 'undefined' || !__firebase_config) {
            console.warn("Firebase configuration is missing. Running in demo mode.");
            setIsDemoMode(true);
            setIsReady(true); // Allow app to render in demo mode
            return;
        }

        try {
            const firebaseConfig = JSON.parse(__firebase_config);
            if (!firebaseConfig.projectId) {
                console.warn("Firebase configuration is invalid: 'projectId' is missing. Running in demo mode.");
                setIsDemoMode(true);
                setIsReady(true);
                return;
            }

            const app = initializeApp(firebaseConfig);
            const firestoreDb = getFirestore(app);
            const firebaseAuth = getAuth(app);

            setDb(firestoreDb);
            setAuth(firebaseAuth);

            // Listen for auth state changes
            const unsubscribe = onAuthStateChanged(firebaseAuth, async (user) => {
                if (user) {
                    setUserId(user.uid);
                } else {
                    try {
                        if (typeof __initial_auth_token !== 'undefined') {
                            await signInWithCustomToken(firebaseAuth, __initial_auth_token);
                        } else {
                            await signInAnonymously(firebaseAuth);
                        }
                    } catch (error) {
                        console.error("Firebase Auth Error:", error);
                        setIsDemoMode(true); // Fallback to demo mode on auth error
                    }
                }
                setIsReady(true);
            });

            return () => unsubscribe();
        } catch (error) {
            console.error("Failed to initialize Firebase:", error);
            setIsDemoMode(true); // Fallback to demo mode on init error
            setIsReady(true);
        }
    }, []);

    // Effect for managing sessions (both Firestore and Demo mode)
    useEffect(() => {
        if (!isReady) return;

        if (isDemoMode) {
            // In demo mode, if there are no sessions, create one.
            if (chatSessions.length === 0) {
                createNewChatSession();
            }
        } else if (db && userId) {
            // Firestore mode
            const appId = typeof __app_id !== 'undefined' ? __app_id : 'default-app-id';
            const chatSessionsRef = collection(db, `artifacts/${appId}/users/${userId}/chatSessions`);
            const q = query(chatSessionsRef, orderBy('updatedAt', 'desc'));

            const unsubscribe = onSnapshot(q, (snapshot) => {
                const sessions = snapshot.docs.map(doc => ({
                    id: doc.id,
                    ...doc.data()
                }));
                setChatSessions(sessions);

                if (!currentSessionId && sessions.length > 0) {
                    setCurrentSessionId(sessions[0].id);
                } else if (snapshot.empty) {
                    createNewChatSession();
                }
            }, (error) => {
                console.error("Error fetching chat sessions:", error);
            });

            return () => unsubscribe();
        }
    }, [isReady, isDemoMode, db, userId]);


    // Effect for fetching messages for the current session
    useEffect(() => {
        if (!currentSessionId || isDemoMode) return; // In demo mode, messages are handled by local state only

        if (isReady && db && userId) {
            const appId = typeof __app_id !== 'undefined' ? __app_id : 'default-app-id';
            const sessionDocRef = doc(db, `artifacts/${appId}/users/${userId}/chatSessions`, currentSessionId);
            const unsubscribe = onSnapshot(sessionDocRef, (docSnap) => {
                if (docSnap.exists()) {
                    const data = docSnap.data();
                    setMessages(Array.isArray(data.messages) ? data.messages : []);
                } else {
                    setMessages([]);
                }
            }, (error) => {
                console.error("Error fetching messages:", error);
            });

            return () => unsubscribe();
        }
    }, [isReady, db, userId, currentSessionId, isDemoMode]);

    // Create a new chat session
    const createNewChatSession = async () => {
        setLoading(true);
        if (isDemoMode) {
            const newSessionId = crypto.randomUUID();
            const newSession = {
                id: newSessionId,
                title: `New Chat (Demo)`,
                messages: [],
                createdAt: new Date(),
                updatedAt: new Date(),
            };
            setChatSessions([newSession, ...chatSessions]);
            setCurrentSessionId(newSessionId);
            setMessages([]);
        } else if (db && userId) {
            try {
                const appId = typeof __app_id !== 'undefined' ? __app_id : 'default-app-id';
                const newSessionRef = await addDoc(collection(db, `artifacts/${appId}/users/${userId}/chatSessions`), {
                    title: `New Chat ${new Date().toLocaleDateString()}`,
                    messages: [],
                    createdAt: new Date(),
                    updatedAt: new Date()
                });
                setCurrentSessionId(newSessionRef.id);
                setMessages([]);
            } catch (error) {
                console.error("Error creating new chat session:", error);
            }
        }
        setLoading(false);
    };
    
    // Selects a chat session
    const selectChatSession = (sessionId) => {
        setCurrentSessionId(sessionId);
        if (isDemoMode) {
            const session = chatSessions.find(s => s.id === sessionId);
            if(session) {
                setMessages(session.messages);
            }
        }
        // For firestore mode, the useEffect for messages will trigger automatically
    };


    // Helper function to render message content
    const renderMessageContent = (text) => {
        const parts = text.split(/(```(?:[a-zA-Z0-9]+)?\n[\s\S]*?\n```)/g);
        return parts.map((part, i) => {
            if (part.startsWith('```')) {
                const codeContent = part.replace(/```(?:[a-zA-Z0-9]+)?\n|```/g, '');
                return (
                    React.createElement("div", { key: i, className: "bg-gray-800 p-0 rounded-md overflow-hidden my-2" },
                        React.createElement("div", { className: "flex items-center justify-between px-3 py-2 bg-gray-700 text-gray-300 text-xs font-semibold" },
                            React.createElement("span", { className: "flex items-center" },
                                React.createElement(LucideIcon, { name: "Code", size: 14, className: "mr-1" }),
                                "Lua Code Example"
                            ),
                            React.createElement("button", { className: "flex items-center text-gray-400 hover:text-gray-100" },
                                React.createElement(LucideIcon, { name: "Copy", size: 14, className: "mr-1" }),
                                "Copy"
                            )
                        ),
                        React.createElement("pre", { className: "p-3 overflow-x-auto text-sm font-mono text-gray-200" },
                            React.createElement("code", null, codeContent)
                        )
                    )
                );
            } else if (part.startsWith('## ')) { // Handle H2 headings for code block titles
                return React.createElement("h2", { key: i, className: "text-lg font-semibold mt-4 mb-2 text-gray-100" }, part.substring(3).trim());
            }
            return React.createElement("p", { key: i, className: "mb-1 last:mb-0" }, part);
        });
    };

    // This function now reads the content from Perception.txt
    useEffect(() => {
        const fetchPerceptionDoc = async () => {
            try {
                const response = await fetch('./Perception.txt');
                if (!response.ok) {
                    throw new Error(`HTTP error! status: ${response.status}`);
                }
                const text = await response.text();
                setPerceptionDocContent(text);
            } catch (error) {
                console.error("Could not load Perception.txt:", error);
                setPerceptionDocContent("Error loading Perception.txt. Please ensure it's in the same directory as index.html.");
            }
        };
        fetchPerceptionDoc();
    }, []);

    // Handle sending a message
    const handleSendMessage = async (e) => {
        e.preventDefault();
        if (!input.trim() || loading || !currentSessionId) return;

        const userMessage = { sender: 'user', text: input.trim(), timestamp: new Date().toISOString() };
        const updatedMessages = [...messages, userMessage];
        setMessages(updatedMessages);
        setInput('');
        setLoading(true);

        // Update state locally first for responsiveness
        if (isDemoMode) {
            const updatedSessions = chatSessions.map(s => 
                s.id === currentSessionId ? { ...s, messages: updatedMessages, updatedAt: new Date() } : s
            );
            setChatSessions(updatedSessions);
        } else if (db && userId) {
            try {
                const appId = typeof __app_id !== 'undefined' ? __app_id : 'default-app-id';
                const sessionDocRef = doc(db, `artifacts/${appId}/users/${userId}/chatSessions`, currentSessionId);
                await updateDoc(sessionDocRef, {
                    messages: updatedMessages,
                    updatedAt: new Date()
                });
            } catch (error) {
                console.error("Error saving user message:", error);
            }
        }

        // --- AI Response ---
        const apiKey = "AIzaSyA3Zhw-Apw21X2AI6cLQWZU7LGttcqhNlE";
        const apiUrl = `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=${apiKey}`;
        const systemPrompt = `You are an AI chatbot specialized in Lua 5.4 and the Perception.cx API. You MUST strictly adhere to the provided Perception.cx API documentation and Lua 5.4 syntax. Only provide code examples and explanations relevant to these two contexts. Do NOT provide information or code outside of Lua 5.4 or the Perception.cx API. Your response should be a single, professional, and well-formatted message. Avoid conversational filler and get straight to the point. When providing code, use Lua syntax highlighting within markdown code blocks. For code examples, provide a clear, concise heading (e.g., "## Generic Lua Watermark Example") before the code block. Ensure the overall response is clean, easy to read, and follows a structure similar to the user's provided example image, with a brief introductory sentence followed by the code block and its heading.`;
        
        const contents = [
            { role: "user", parts: [{ text: `${systemPrompt}\n\nPerception.cx API Documentation:\n${perceptionDocContent}` }] },
            { role: "model", parts: [{ text: "Understood. I will strictly adhere to Lua 5.4 and the Perception.cx API documentation provided, providing only one professional response with proper formatting and no external library references. I will ensure a concise introduction, clear code block headings, and proper Lua syntax highlighting." }] },
            ...updatedMessages.map(msg => ({ role: msg.sender === 'user' ? 'user' : 'model', parts: [{ text: msg.text }] }))
        ];

        try {
            const response = await fetch(apiUrl, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ contents })
            });

            let aiResponseText = "Sorry, I couldn't get a response.";
            if (response.ok) {
                const result = await response.json();
                aiResponseText = result.candidates?.[0]?.content?.parts?.[0]?.text || aiResponseText;
            } else {
                console.error("AI API Error:", await response.text());
                aiResponseText = "There was an error connecting to the AI. Please check the console.";
            }

            const aiMessage = { sender: 'ai', text: aiResponseText, timestamp: new Date().toISOString() };
            const finalMessages = [...updatedMessages, aiMessage];
            setMessages(finalMessages);

            // Save AI response
            if (isDemoMode) {
                const updatedSessions = chatSessions.map(s => 
                    s.id === currentSessionId ? { ...s, messages: finalMessages, updatedAt: new Date() } : s
                );
                setChatSessions(updatedSessions);
            } else if (db && userId) {
                const appId = typeof __app_id !== 'undefined' ? __app_id : 'default-app-id';
                const sessionDocRef = doc(db, `artifacts/${appId}/users/${userId}/chatSessions`, currentSessionId);
                await updateDoc(sessionDocRef, { messages: finalMessages, updatedAt: new Date() });
            }
        } catch (error) {
            console.error("Error with AI response:", error);
        } finally {
            setLoading(false);
        }
    };

    // SVG icon component
    const LucideIcon = ({ name, size = 20, className = '' }) => {
        const icons = {
            'SquarePen': React.createElement('svg', { xmlns: 'http://www.w3.org/2000/svg', width: size, height: size, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', strokeWidth: '2', strokeLinecap: 'round', strokeLinejoin: 'round', className: className }, React.createElement('path', { d: 'M12 20h9' }), React.createElement('path', { d: 'M16.5 3.5a2.12 2.12 0 0 1 3 3L7 19l-4 1 1-4Z' })),
            'Search': React.createElement('svg', { xmlns: 'http://www.w3.org/2000/svg', width: size, height: size, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', strokeWidth: '2', strokeLinecap: 'round', strokeLinejoin: 'round', className: className }, React.createElement('circle', { cx: '11', cy: '11', r: '8' }), React.createElement('path', { d: 'm21 21-4.3-4.3' })),
            'Sparkles': React.createElement('svg', { xmlns: 'http://www.w3.org/2000/svg', width: size, height: size, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', strokeWidth: '2', strokeLinecap: 'round', strokeLinejoin: 'round', className: className }, React.createElement('path', { d: 'm12 3-1.9 3.8-3.8 1.9 3.8 1.9L12 15l1.9-3.8 3.8-1.9-3.8-1.9L12 3z' })),
            'Image': React.createElement('svg', { xmlns: 'http://www.w3.org/2000/svg', width: size, height: size, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', strokeWidth: '2', strokeLinecap: 'round', strokeLinejoin: 'round', className: className }, React.createElement('rect', { width: '18', height: '18', x: '3', y: '3', rx: '2', ry: '2' }), React.createElement('circle', { cx: '9', cy: '9', r: '2' }), React.createElement('path', { d: 'm21 15-3.086-3.086a2 2 0 0 0-2.828 0L6 21' })),
            'Code': React.createElement('svg', { xmlns: 'http://www.w3.org/2000/svg', width: size, height: size, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', strokeWidth: '2', strokeLinecap: 'round', strokeLinejoin: 'round', className: className }, React.createElement('polyline', { points: '16 18 22 12 16 6' }), React.createElement('polyline', { points: '8 6 2 12 8 18' })),
            'Copy': React.createElement('svg', { xmlns: 'http://www.w3.org/2000/svg', width: size, height: size, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', strokeWidth: '2', strokeLinecap: 'round', strokeLinejoin: 'round', className: className }, React.createElement('rect', { width: '14', height: '14', x: '8', y: '8', rx: '2', ry: '2' }), React.createElement('path', { d: 'M4 16c-1.1 0-2-.9-2-2V4c0-1.1.9-2 2-2h10c1.1 0 2 .9 2 2v2' })),
            'Settings': React.createElement('svg', { xmlns: 'http://www.w3.org/2000/svg', width: size, height: size, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', strokeWidth: '2', strokeLinecap: 'round', strokeLinejoin: 'round', className: className }, React.createElement('path', { d: 'M12.22 2h-.44a2 2 0 0 0-2 2v.18a2 2 0 0 1-1 1.73l-.43.25a2 2 0 0 1-2 0l-.15-.08a2 2 0 0 0-2.73.73l-.22.38a2 2 0 0 0 .73 2.73l.15.1a2 2 0 0 1 1 1.72v.51a2 2 0 0 1-1 1.74l-.15.09a2 2 0 0 0-.73 2.73l.22.38a2 2 0 0 0 2.73.73l.15-.08a2 2 0 0 1 2 0l.43.25a2 2 0 0 1 1 1.73V20a2 2 0 0 0 2 2h.44a2 2 0 0 0 2-2v-.18a2 2 0 0 1 1-1.73l.43-.25a2 2 0 0 1 2 0l.15.08a2 2 0 0 0 2.73-.73l.22-.39a2 2 0 0 0-.73-2.73l-.15-.08a2 2 0 0 1-1-1.74v-.5a2 2 0 0 1 1-1.74l.15-.09a2 2 0 0 0 .73-2.73l-.22-.38a2 2 0 0 0-2.73-.73l-.15.08a2 2 0 0 1-2 0l-.43-.25a2 2 0 0 1-1-1.73V4a2 2 0 0 0-2-2z' }), React.createElement('circle', { cx: '12', cy: '12', r: '3' })),
            'Library': React.createElement('svg', { xmlns: 'http://www.w3.org/2000/svg', width: size, height: size, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', strokeWidth: '2', strokeLinecap: 'round', strokeLinejoin: 'round', className: className }, React.createElement('path', { d: 'm16 6 4 14' }), React.createElement('path', { d: 'M12 6v14' }), React.createElement('path', { d: 'M8 8v12' }), React.createElement('path', { d: 'M4 4v16' })),
            'Plus': React.createElement('svg', { xmlns: 'http://www.w3.org/2000/svg', width: size, height: size, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', strokeWidth: '2', strokeLinecap: 'round', strokeLinejoin: 'round', className: className }, React.createElement('path', { d: 'M5 12h14' }), React.createElement('path', { d: 'M12 5v14' })),
            'Send': React.createElement('svg', { xmlns: 'http://www.w3.org/2000/svg', width: size, height: size, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', strokeWidth: '2', strokeLinecap: 'round', strokeLinejoin: 'round', className: className }, React.createElement('path', { d: 'M14.536 21.686a.5.5 0 0 0 .937-.024l6.5-19a.496.496 0 0 0-.635-.635l-19 6.5a.5.5 0 0 0-.024.937l7.93 3.18a2 2 0 0 1 1.112 1.11z' }), React.createElement('path', { d: 'm21.854 2.147-10.94 10.939' })),
            'Mic': React.createElement('svg', { xmlns: 'http://www.w3.org/2000/svg', width: size, height: size, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', strokeWidth: '2', strokeLinecap: 'round', strokeLinejoin: 'round', className: className }, React.createElement('path', { d: 'M12 2a3 3 0 0 0-3 3v7a3 3 0 0 0 6 0V5a3 3 0 0 0-3-3Z' }), React.createElement('path', { d: 'M19 10v2a7 7 0 0 1-14 0v-2' }), React.createElement('line', { x1: '12', x2: '12', y1: '19', y2: '22' }), React.createElement('line', { x1: '8', x2: '16', y1: '22', y2: '22' })),
            'Paperclip': React.createElement('svg', { xmlns: 'http://www.w3.org/2000/svg', width: size, height: size, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', strokeWidth: '2', strokeLinecap: 'round', strokeLinejoin: 'round', className: className }, React.createElement('path', { d: 'm21.44 11.05-9.19 9.19a6 6 0 0 1-8.49-8.49l8.57-8.57A4 4 0 1 1 18 8.84l-8.59 8.57a2 2 0 0 1-2.83-2.83l8.49-8.48' }))
        };
        return icons[name] || null;
    };

    return (
        React.createElement("div", { className: "flex h-screen bg-gray-900 text-white" },
            // Sidebar - ChatGPT style
            React.createElement("div", { className: "w-64 chatgpt-sidebar flex flex-col" },
                // Top section with logo and new chat
                React.createElement("div", { className: "p-3" },
                    React.createElement("div", { className: "flex items-center justify-between mb-3" },
                        React.createElement("div", { className: "flex items-center" },
                            React.createElement(LucideIcon, { name: "Settings", size: 20, className: "text-gray-400" }),
                            React.createElement("span", { className: "ml-2 text-lg font-semibold" }, "ChatGPT")
                        )
                    ),
                    React.createElement("button", { 
                        onClick: createNewChatSession, 
                        className: "w-full flex items-center justify-center py-2.5 px-3 rounded-lg border border-gray-600 hover:bg-gray-700 transition-colors text-sm font-medium"
                    },
                        React.createElement(LucideIcon, { name: "Plus", size: 16, className: "mr-2" }),
                        "New chat"
                    )
                ),
                
                // Navigation items
                React.createElement("div", { className: "px-3 mb-4" },
                    React.createElement("div", { className: "chatgpt-sidebar-item flex items-center py-2.5 px-3 text-sm cursor-pointer" },
                        React.createElement(LucideIcon, { name: "Search", size: 16, className: "mr-3 text-gray-400" }),
                        "Search chats"
                    ),
                    React.createElement("div", { className: "chatgpt-sidebar-item flex items-center py-2.5 px-3 text-sm cursor-pointer" },
                        React.createElement(LucideIcon, { name: "Library", size: 16, className: "mr-3 text-gray-400" }),
                        "Library"
                    )
                ),
                
                // Chat sessions
                React.createElement("div", { className: "flex-1 overflow-y-auto px-3" },
                    React.createElement("div", { className: "text-xs text-gray-500 mb-2 px-3" }, "Chats"),
                    chatSessions.map(session => (
                        React.createElement("div", { 
                            key: session.id, 
                            onClick: () => selectChatSession(session.id), 
                            className: `chatgpt-sidebar-item cursor-pointer py-2.5 px-3 mb-1 text-sm truncate ${currentSessionId === session.id ? 'active' : ''}` 
                        },
                            session.title || `Chat ${new Date(session.createdAt).toLocaleDateString()}`
                        )
                    ))
                ),
                
                // Bottom section
                React.createElement("div", { className: "p-3 border-t border-gray-700" },
                    isDemoMode && React.createElement("div", { className: "text-xs text-yellow-400 mb-2" }, "Demo Mode"),
                    React.createElement("div", { className: "chatgpt-sidebar-item flex items-center py-2.5 px-3 text-sm cursor-pointer" },
                        React.createElement("div", { className: "w-6 h-6 bg-blue-600 rounded-full flex items-center justify-center mr-3 text-xs font-bold" }, "S"),
                        "Upgrade plan"
                    )
                )
            ),

            // Main chat area - ChatGPT style
            React.createElement("div", { className: "flex-1 flex flex-col chatgpt-main" },
                // Header
                React.createElement("div", { className: "flex items-center justify-between p-4 border-b border-gray-700" },
                    React.createElement("h1", { className: "text-xl font-semibold" }, "ChatGPT"),
                    React.createElement("div", { className: "flex items-center space-x-2" },
                        React.createElement("button", { className: "p-2 hover:bg-gray-700 rounded-lg" },
                            React.createElement(LucideIcon, { name: "Settings", size: 20 })
                        )
                    )
                ),
                
                // Messages area
                React.createElement("div", { className: "flex-1 overflow-y-auto" },
                    messages.length === 0 ? (
                        // Empty state - like ChatGPT
                        React.createElement("div", { className: "flex flex-col items-center justify-center h-full px-4" },
                            React.createElement("h2", { className: "text-3xl font-semibold mb-8 text-center" }, "What can I help with?"),
                            React.createElement("div", { className: "grid grid-cols-2 gap-3 max-w-2xl w-full" },
                                React.createElement("div", { className: "p-4 border border-gray-600 rounded-xl hover:bg-gray-800 cursor-pointer" },
                                    React.createElement("div", { className: "text-sm font-medium mb-1" }, "Create a watermark"),
                                    React.createElement("div", { className: "text-xs text-gray-400" }, "Using Lua and Perception.cx API")
                                ),
                                React.createElement("div", { className: "p-4 border border-gray-600 rounded-xl hover:bg-gray-800 cursor-pointer" },
                                    React.createElement("div", { className: "text-sm font-medium mb-1" }, "Render text"),
                                    React.createElement("div", { className: "text-xs text-gray-400" }, "With custom fonts and colors")
                                ),
                                React.createElement("div", { className: "p-4 border border-gray-600 rounded-xl hover:bg-gray-800 cursor-pointer" },
                                    React.createElement("div", { className: "text-sm font-medium mb-1" }, "Handle user input"),
                                    React.createElement("div", { className: "text-xs text-gray-400" }, "Process keyboard and mouse events")
                                ),
                                React.createElement("div", { className: "p-4 border border-gray-600 rounded-xl hover:bg-gray-800 cursor-pointer" },
                                    React.createElement("div", { className: "text-sm font-medium mb-1" }, "Debug Lua code"),
                                    React.createElement("div", { className: "text-xs text-gray-400" }, "Find and fix common issues")
                                )
                            )
                        )
                    ) : (
                        // Messages
                        React.createElement("div", { className: "max-w-3xl mx-auto px-4 py-6" },
                            messages.map((msg, index) => (
                                React.createElement("div", { key: index, className: "mb-6" },
                                    React.createElement("div", { className: "flex items-start space-x-3" },
                                        React.createElement("div", { className: `w-8 h-8 rounded-full flex items-center justify-center text-sm font-bold ${msg.sender === 'user' ? 'bg-blue-600' : 'bg-green-600'}` },
                                            msg.sender === 'user' ? 'U' : 'AI'
                                        ),
                                        React.createElement("div", { className: "flex-1 min-w-0" },
                                            React.createElement("div", { className: `${msg.sender === 'user' ? 'chatgpt-message-user p-3' : 'chatgpt-message-ai'}` },
                                                renderMessageContent(msg.text)
                                            )
                                        )
                                    )
                                )
                            )),
                            React.createElement("div", { ref: messagesEndRef })
                        )
                    )
                ),

                // Input area - ChatGPT style
                React.createElement("div", { className: "p-4" },
                    React.createElement("div", { className: "max-w-3xl mx-auto" },
                        React.createElement("form", { onSubmit: handleSendMessage, className: "relative" },
                            React.createElement("div", { className: "chatgpt-input-area flex items-end p-3" },
                                React.createElement("button", { type: "button", className: "p-2 hover:bg-gray-600 rounded-lg mr-2" },
                                    React.createElement(LucideIcon, { name: "Paperclip", size: 20, className: "text-gray-400" })
                                ),
                                React.createElement("textarea", {
                                    value: input,
                                    onChange: (e) => setInput(e.target.value),
                                    placeholder: "Ask anything",
                                    className: "flex-1 bg-transparent text-white placeholder-gray-400 resize-none outline-none max-h-32 min-h-[24px]",
                                    rows: 1,
                                    onKeyDown: (e) => {
                                        if (e.key === 'Enter' && !e.shiftKey) {
                                            e.preventDefault();
                                            handleSendMessage(e);
                                        }
                                    }
                                }),
                                React.createElement("div", { className: "flex items-center space-x-2 ml-2" },
                                    React.createElement("button", { type: "button", className: "p-2 hover:bg-gray-600 rounded-lg" },
                                        React.createElement(LucideIcon, { name: "Mic", size: 20, className: "text-gray-400" })
                                    ),
                                    React.createElement("button", {
                                        type: "submit",
                                        className: `p-2 rounded-lg ${input.trim() && !loading ? 'chatgpt-button-primary text-white' : 'bg-gray-600 text-gray-400 cursor-not-allowed'}`,
                                        disabled: !input.trim() || loading
                                    },
                                        loading ? 
                                            React.createElement(LucideIcon, { name: "Sparkles", size: 20, className: "animate-pulse" }) :
                                            React.createElement(LucideIcon, { name: "Send", size: 20 })
                                    )
                                )
                            )
                        ),
                        React.createElement("div", { className: "text-xs text-gray-500 text-center mt-2" },
                            "ChatGPT can make mistakes. Consider checking important information."
                        )
                    )
                )
            )
        )
    );
};

// Render the App component into the DOM
ReactDOM.render(React.createElement(App, null), document.getElementById('root'));

