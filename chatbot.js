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
    const [luaExamplesContent, setLuaExamplesContent] = useState('');

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
                    React.createElement("div", { key: i, className: "code-block" },
                        React.createElement("div", { className: "code-header" },
                            React.createElement("span", { className: "flex items-center" },
                                React.createElement(LucideIcon, { name: "Code", size: 14, className: "mr-1" }),
                                "Lua Code Example"
                            ),
                            React.createElement("button", { className: "flex items-center text-gray-400 hover:text-gray-100" },
                                React.createElement(LucideIcon, { name: "Copy", size: 14, className: "mr-1" }),
                                "Copy"
                            )
                        ),
                        React.createElement("pre", { className: "code-content" },
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

    // This function now reads the content from Perception.txt and Lua example files
    useEffect(() => {
        const fetchPerceptionAndLuaExamples = async () => {
            let combinedContent = '';
            try {
                // Fetch Perception.txt
                const perceptionResponse = await fetch('./Perception.txt');
                if (!perceptionResponse.ok) {
                    throw new Error(`HTTP error! status: ${perceptionResponse.status} for Perception.txt`);
                }
                const perceptionText = await perceptionResponse.text();
                combinedContent += `Perception.cx API Documentation:\n${perceptionText}\n\n`;
                setPerceptionDocContent(perceptionText); // Keep separate state for Perception.txt if needed elsewhere
            } catch (error) {
                console.error("Could not load Perception.txt:", error);
                combinedContent += "Error loading Perception.txt. Please ensure it's in the same directory as index.html.\n\n";
            }

            // Fetch Lua example files from the 'Examples' folder
            const luaFiles = [
                'DayZ.lua',
                'delta_force.lua',
                'fortnite.lua',
                'lagger.lua',
                'ragemp.lua',
                'roblox.lua',
                'rust.lua'
            ];

            let examplesCombined = '';
            for (const file of luaFiles) {
                try {
                    const response = await fetch(`./Examples/${file}`);
                    if (!response.ok) {
                        throw new Error(`HTTP error! status: ${response.status} for ${file}`);
                    }
                    const text = await response.text();
                    examplesCombined += `-- Content from ${file}:\n${text}\n\n`;
                } catch (error) {
                    console.error(`Could not load ${file}:`, error);
                    examplesCombined += `Error loading ${file}.\n\n`;
                }
            }
            setLuaExamplesContent(examplesCombined); // Store combined Lua examples
            combinedContent += `Lua Code Examples for Learning:\n${examplesCombined}`;

            // Update the system prompt with combined content
            // This part will be handled in handleSendMessage to ensure it's always fresh

        };
        fetchPerceptionAndLuaExamples();
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
        
        // Construct the system prompt with combined documentation and examples
        const systemPrompt = `You are an AI chatbot specialized in Lua 5.4 and the Perception.cx API. You MUST strictly adhere to the provided Perception.cx API documentation and Lua 5.4 syntax, you can also make an external/custom lua library based on what the user wants. Only provide code examples and explanations relevant to these two contexts. Do NOT provide information or code outside of Lua 5.4 or the Perception.cx API. Your response should be a single, professional, and well-formatted message. Avoid conversational filler and get straight to the point. When providing code, use Lua syntax highlighting within markdown code blocks. For code examples, provide a clear, concise heading (e.g., "## Generic Lua Watermark Example") before the code block. Ensure the overall response is clean, easy to read, and follows a structure similar to the user's provided example image, with a brief introductory sentence followed by the code block and its heading. Use the provided Lua examples to learn and improve your responses, making them more accurate and relevant to the user's needs.`;
        
        const contents = [
            { role: "user", parts: [{ text: `${systemPrompt}\n\nPerception.cx API Documentation:\n${perceptionDocContent}\n\nLua Code Examples for Learning:\n${luaExamplesContent}` }] },
            { role: "model", parts: [{ text: "Understood. I will strictly adhere to Lua 5.4 and the Perception.cx API documentation and provided examples, providing only one professional response with proper formatting and no external library references but if a user wants to be able to make an external library like ffi/luajit bit HTTP and more you will make those for the user. I will ensure a concise introduction, clear code block headings, and proper Lua syntax highlighting." }] },
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
            'Sparkles': React.createElement('svg', { xmlns: 'http://www.w3.org/2000/svg', width: size, height: size, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', strokeWidth: '2', strokeLinecap: 'round', strokeLinejoin: 'round', className: className }, React.createElement('path', { d: 'M9.8 1.8 7 10.2 1.8 12l5.2 1.8L9.8 22l5.2-8.4 5.2 1.8-5.2-1.8L14.2 2l-5.2 8.4Z' })),
            'Code': React.createElement('svg', { xmlns: 'http://www.w3.org/2000/svg', width: size, height: size, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', strokeWidth: '2', strokeLinecap: 'round', strokeLinejoin: 'round', className: className }, React.createElement('path', { d: 'm16 4 4 4-4 4' }), React.createElement('path', { d: 'm8 12-4-4 4-4' }), React.createElement('path', { d: 'm21 12-4 6-4-6' }), React.createElement('path', { d: 'm3 12 4 6 4-6' })),
            'Copy': React.createElement('svg', { xmlns: 'http://www.w3.org/2000/svg', width: size, height: size, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', strokeWidth: '2', strokeLinecap: 'round', strokeLinejoin: 'round', className: className }, React.createElement('rect', { width: '14', height: '14', x: '8', y: '8', rx: '2', ry: '2' }), React.createElement('path', { d: 'M4 16c-1.1 0-2-.9-2-2V4c0-1.1.9-2 2-2h10c1.1 0 2 .9 2 2' })),
            'MessageSquare': React.createElement('svg', { xmlns: 'http://www.w3.org/2000/svg', width: size, height: size, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', strokeWidth: '2', strokeLinecap: 'round', strokeLinejoin: 'round', className: className }, React.createElement('path', { d: 'M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z' })),
            'User': React.createElement('svg', { xmlns: 'http://www.w3.org/2000/svg', width: size, height: size, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', strokeWidth: '2', strokeLinecap: 'round', strokeLinejoin: 'round', className: className }, React.createElement('path', { d: 'M19 21v-2a4 4 0 0 0-4-4H9a4 4 0 0 0-4 4v2' }), React.createElement('circle', { cx: '12', cy: '7', r: '4' })),
            'Bot': React.createElement('svg', { xmlns: 'http://www.w3.org/2000/svg', width: size, height: size, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', strokeWidth: '2', strokeLinecap: 'round', strokeLinejoin: 'round', className: className }, React.createElement('path', { d: 'M12 8V4H8' }), React.createElement('path', { d: 'M22 12a10 10 0 1 1-20 0 10 10 0 0 1 20 0Z' }), React.createElement('path', { d: 'M2 12s3 0 4 2 5 0 6 0 4-2 4-2' }), React.createElement('path', { d: 'M9 9h.01' }), React.createElement('path', { d: 'M15 9h.01' })),
            'Plus': React.createElement('svg', { xmlns: 'http://www.w3.org/2000/svg', width: size, height: size, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', strokeWidth: '2', strokeLinecap: 'round', strokeLinejoin: 'round', className: className }, React.createElement('path', { d: 'M12 5v14' }), React.createElement('path', { d: 'M5 12h14' })),
            'Mic': React.createElement('svg', { xmlns: 'http://www.w3.org/2000/svg', width: size, height: size, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', strokeWidth: '2', strokeLinecap: 'round', strokeLinejoin: 'round', className: className }, React.createElement('path', { d: 'M12 2a3 3 0 0 0-3 3v7a3 3 0 0 0 6 0V5a3 3 0 0 0-3-3Z' }), React.createElement('path', { d: 'M19 10v2a7 7 0 0 1-14 0v-2' }), React.createElement('path', { d: 'M12 19v3' }), React.createElement('path', { d: 'M8 22h8' })),
            'Image': React.createElement('svg', { xmlns: 'http://www.w3.org/2000/svg', width: size, height: size, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', strokeWidth: '2', strokeLinecap: 'round', strokeLinejoin: 'round', className: className }, React.createElement('rect', { width: '18', height: '18', x: '3', y: '3', rx: '2', ry: '2' }), React.createElement('circle', { cx: '9', cy: '9', r: '2' }), React.createElement('path', { d: 'm21 15-3.086-3.086a2 2 0 0 0-2.828 0L6 21' })),
            'Send': React.createElement('svg', { xmlns: 'http://www.w3.org/2000/svg', width: size, height: size, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', strokeWidth: '2', strokeLinecap: 'round', strokeLinejoin: 'round', className: className }, React.createElement('path', { d: 'm22 2-7 20-4-9-9-4 20-7Z' }), React.createElement('path', { d: 'M22 2 11 13' })),
            'Settings': React.createElement('svg', { xmlns: 'http://www.w3.org/2000/svg', width: size, height: size, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', strokeWidth: '2', strokeLinecap: 'round', strokeLinejoin: 'round', className: className }, React.createElement('path', { d: 'M12.22 2h-.44a2 2 0 0 0-2 2v.18a2 2 0 0 1-1 1.73l-.43.25a2 2 0 0 1-2 0l-.15-.08a2 2 0 0 0-2.73.73l-.78 1.28a2 2 0 0 0 .73 2.73l.04.02a2 2 0 0 1 .97 1.91v.44a2 2 0 0 1-.97 1.91l-.04.02a2 2 0 0 0-.73 2.73l.78 1.28a2 2 0 0 0 2.73.73l.15-.08a2 2 0 0 1 2 0l.43.25a2 2 0 0 1 1 1.73V20a2 2 0 0 0 2 2h.44a2 2 0 0 0 2-2v-.18a2 2 0 0 1 1-1.73l.43-.25a2 2 0 0 1 2 0l.15.08a2 2 0 0 0 2.73-.73l.78-1.28a2 2 0 0 0-.73-2.73l-.04-.02a2 2 0 0 1-.97-1.91v-.44a2 2 0 0 1 .97-1.91l.04-.02a2 2 0 0 0 .73-2.73l-.78-1.28a2 2 0 0 0-2.73-.73l-.15.08a2 2 0 0 1-2 0l-.43-.25a2 2 0 0 1-1-1.73V4a2 2 0 0 0-2-2z' }), React.createElement('circle', { cx: '12', cy: '12', r: '3' })),
            'HelpCircle': React.createElement('svg', { xmlns: 'http://www.w3.org/2000/svg', width: size, height: size, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', strokeWidth: '2', strokeLinecap: 'round', strokeLinejoin: 'round', className: className }, React.createElement('circle', { cx: '12', cy: '12', r: '10' }), React.createElement('path', { d: 'M9.09 9a3 3 0 0 1 5.83 1c0 2-3 3-3 3' }), React.createElement('path', { d: 'M12 17h.01' })),
            'Archive': React.createElement('svg', { xmlns: 'http://www.w3.org/2000/svg', width: size, height: size, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', strokeWidth: '2', strokeLinecap: 'round', strokeLinejoin: 'round', className: className }, React.createElement('rect', { width: '20', height: '5', x: '2', y: '3', rx: '1' }), React.createElement('path', { d: 'M4 8v11a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8' }), React.createElement('path', { d: 'M10 12h4' })),
            'Trash2': React.createElement('svg', { xmlns: 'http://www.w3.org/2000/svg', width: size, height: size, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', strokeWidth: '2', strokeLinecap: 'round', strokeLinejoin: 'round', className: className }, React.createElement('path', { d: 'M3 6h18' }), React.createElement('path', { d: 'M19 6v14c0 1-1 2-2 2H7c-1 0-2-1-2-2V6' }), React.createElement('path', { d: 'M8 6V4c0-1 1-2 2-2h4c1 0 2 1 2 2v2' }), React.createElement('line', { x1: '10', x2: '10', y1: '11', y2: '17' }), React.createElement('line', { x1: '14', x2: '14', y1: '11', y2: '17' })),
            'ChevronDown': React.createElement('svg', { xmlns: 'http://www.w3.org/2000/svg', width: size, height: size, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', strokeWidth: '2', strokeLinecap: 'round', strokeLinejoin: 'round', className: className }, React.createElement('path', { d: 'm6 9 6 6 6-6' })),
            'Ellipsis': React.createElement('svg', { xmlns: 'http://www.w3.org/2000/svg', width: size, height: size, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', strokeWidth: '2', strokeLinecap: 'round', strokeLinejoin: 'round', className: className }, React.createElement('circle', { cx: '12', cy: '12', r: '1' }), React.createElement('circle', { cx: '19', cy: '12', r: '1' }), React.createElement('circle', { cx: '5', cy: '12', r: '1' })),
            'ExternalLink': React.createElement('svg', { xmlns: 'http://www.w3.org/2000/svg', width: size, height: size, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', strokeWidth: '2', strokeLinecap: 'round', strokeLinejoin: 'round', className: className }, React.createElement('path', { d: 'M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6' }), React.createElement('polyline', { points: '15 3 21 3 21 9' }), React.createElement('line', { x1: '10', x2: '21', y1: '14', y2: '3' })),
            'FileText': React.createElement('svg', { xmlns: 'http://www.w3.org/2000/svg', width: size, height: size, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', strokeWidth: '2', strokeLinecap: 'round', strokeLinejoin: 'round', className: className }, React.createElement('path', { d: 'M15 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V7Z' }), React.createElement('path', { d: 'M14 2v4a2 2 0 0 0 2 2h4' }), React.createElement('path', { d: 'M10 9H8' }), React.createElement('path', { d: 'M16 13H8' }), React.createElement('path', { d: 'M16 17H8' })),
            'Folder': React.createElement('svg', { xmlns: 'http://www.w3.org/2000/svg', width: size, height: size, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', strokeWidth: '2', strokeLinecap: 'round', strokeLinejoin: 'round', className: className }, React.createElement('path', { d: 'M20 20a2 2 0 0 0 2-2V8a2 2 0 0 0-2-2h-7.9a2 2 0 0 1-1.69-.9L9.6 3.9A2 2 0 0 0 7.93 3H4a2 2 0 0 0-2 2v13a2 2 0 0 0 2 2Z' })),
            'Settings2': React.createElement('svg', { xmlns: 'http://www.w3.org/2000/svg', width: size, height: size, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', strokeWidth: '2', strokeLinecap: 'round', strokeLinejoin: 'round', className: className }, React.createElement('path', { d: 'M20 7h-9' }), React.createElement('path', { d: 'M14 17H5' }), React.createElement('circle', { cx: '17', cy: '17', r: '3' }), React.createElement('circle', { cx: '7', cy: '7', r: '3' })),
            'LayoutDashboard': React.createElement('svg', { xmlns: 'http://www.w3.org/2000/svg', width: size, height: size, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', strokeWidth: '2', strokeLinecap: 'round', strokeLinejoin: 'round', className: className }, React.createElement('rect', { width: '7', height: '9', x: '3', y: '3', rx: '1' }), React.createElement('rect', { width: '7', height: '5', x: '14', y: '3', rx: '1' }), React.createElement('rect', { width: '7', height: '9', x: '14', y: '12', rx: '1' }), React.createElement('rect', { width: '7', height: '5', x: '3', y: '16', rx: '1' })),
            'Book': React.createElement('svg', { xmlns: 'http://www.w3.org/2000/svg', width: size, height: size, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', strokeWidth: '2', strokeLinecap: 'round', strokeLinejoin: 'round', className: className }, React.createElement('path', { d: 'M4 19.5v-15A2.5 2.5 0 0 1 6.5 2H20v20H6.5a2.5 2.5 0 0 1 0-5H20' })),
            'MessageSquarePlus': React.createElement('svg', { xmlns: 'http://www.w3.org/2000/svg', width: size, height: size, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', strokeWidth: '2', strokeLinecap: 'round', strokeLinejoin: 'round', className: className }, React.createElement('path', { d: 'M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z' }), React.createElement('path', { d: 'M12 7v6' }), React.createElement('path', { d: 'M15 10H9' })),
            'MessagesSquare': React.createElement('svg', { xmlns: 'http://www.w3.org/2000/svg', width: size, height: size, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', strokeWidth: '2', strokeLinecap: 'round', strokeLinejoin: 'round', className: className }, React.createElement('path', { d: 'M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z' }), React.createElement('path', { d: 'M15 2v4a2 2 0 0 0 2 2h4' }), React.createElement('path', { d: 'M10 9H8' }), React.createElement('path', { d: 'M16 13H8' }), React.createElement('path', { d: 'M16 17H8' })),
            'CircleUser': React.createElement('svg', { xmlns: 'http://www.w3.org/2000/svg', width: size, height: size, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', strokeWidth: '2', strokeLinecap: 'round', strokeLinejoin: 'round', className: className }, React.createElement('circle', { cx: '12', cy: '12', r: '10' }), React.createElement('circle', { cx: '12', cy: '10', r: '3' }), React.createElement('path', { d: 'M7 20.662V19a2 2 0 0 1 2-2h6a2 2 0 0 1 2 2v1.662' })),
            'LogOut': React.createElement('svg', { xmlns: 'http://www.w3.org/2000/svg', width: size, height: size, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', strokeWidth: '2', strokeLinecap: 'round', strokeLinejoin: 'round', className: className }, React.createElement('path', { d: 'M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4' }), React.createElement('polyline', { points: '17 16 22 12 17 8' }), React.createElement('line', { x1: '22', x2: '10', y1: '12', y2: '12' })),
            'X': React.createElement('svg', { xmlns: 'http://www.w3.org/2000/svg', width: size, height: size, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', strokeWidth: '2', strokeLinecap: 'round', strokeLinejoin: 'round', className: className }, React.createElement('path', { d: 'M18 6 6 18' }), React.createElement('path', { d: 'm6 6 12 12' })),
            'Menu': React.createElement('svg', { xmlns: 'http://www.w3.org/2000/svg', width: size, height: size, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', strokeWidth: '2', strokeLinecap: 'round', strokeLinejoin: 'round', className: className }, React.createElement('line', { x1: '4', x2: '20', y1: '12', y2: '12' }), React.createElement('line', { x1: '4', x2: '20', y1: '6', y2: '6' }), React.createElement('line', { x1: '4', x2: '20', y1: '18', y2: '18' })),
            'MessageSquareText': React.createElement('svg', { xmlns: 'http://www.w3.org/2000/svg', width: size, height: size, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', strokeWidth: '2', strokeLinecap: 'round', strokeLinejoin: 'round', className: className }, React.createElement('path', { d: 'M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z' }), React.createElement('path', { d: 'M11 9h6' }), React.createElement('path', { d: 'M11 13h6' }), React.createElement('path', { d: 'M7 9h2' }), React.createElement('path', { d: 'M7 13h2' })),
            'ArrowUp': React.createElement('svg', { xmlns: 'http://www.w3.org/2000/svg', width: size, height: size, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', strokeWidth: '2', strokeLinecap: 'round', strokeLinejoin: 'round', className: className }, React.createElement('path', { d: 'M12 19V5' }), React.createElement('path', { d: 'm5 12 7-7 7 7' })),
            'SendHorizonal': React.createElement('svg', { xmlns: 'http://www.w3.org/2000/svg', width: size, height: size, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', strokeWidth: '2', strokeLinecap: 'round', strokeLinejoin: 'round', className: className }, React.createElement('path', { d: 'm15 12-8-5V4l16 8-16 8v-3l8-5Z' }), React.createElement('path', { d: 'M22 12H7' })),
            'PlusCircle': React.createElement('svg', { xmlns: 'http://www.w3.org/2000/svg', width: size, height: size, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', strokeWidth: '2', strokeLinecap: 'round', strokeLinejoin: 'round', className: className }, React.createElement('circle', { cx: '12', cy: '12', r: '10' }), React.createElement('path', { d: 'M8 12h8' }), React.createElement('path', { d: 'M12 8v8' })),
            'WandSparkles': React.createElement('svg', { xmlns: 'http://www.w3.org/2000/svg', width: size, height: size, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', strokeWidth: '2', strokeLinecap: 'round', strokeLinejoin: 'round', className: className }, React.createElement('path', { d: 'M21.9 16.9a2 2 0 0 0-.1-3.7l-1.9-1.2a2 2 0 0 1-1-.7l-.5-1a2 2 0 0 0-1.8-1.1h-1.1a2 2 0 0 1-1.7-1L12.3 2.9a2 2 0 0 0-3.7-.1l-1.2 1.9a2 2 0 0 1-.7 1l-1 .5a2 2 0 0 0-1.1 1.8v1.1a2 2 0 0 1-1 1.7L2.1 12.3a2 2 0 0 0 .1 3.7l1.9 1.2a2 2 0 0 1 1 .7l.5 1a2 2 0 0 0 1.8 1.1h1.1a2 2 0 0 1 1.7 1l.9 1.8a2 2 0 0 0 3.7.1l1.2-1.9a2 2 0 0 1 .7-1l1-.5a2 2 0 0 0 1.1-1.8v-1.1a2 2 0 0 1 1-1.7Z' }), React.createElement('path', { d: 'M14.5 8.5 16 10' }), React.createElement('path', { d: 'M8.5 14.5 10 16' })),
            'Brain': React.createElement('svg', { xmlns: 'http://www.w3.org/2000/svg', width: size, height: size, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', strokeWidth: '2', strokeLinecap: 'round', strokeLinejoin: 'round', className: className }, React.createElement('path', { d: 'M9.5 22a2.5 2.5 0 0 1-5-5 2.5 2.5 0 0 1 5-5 2.5 2.5 0 0 1 5 5 2.5 2.5 0 0 1-5 5Z' }), React.createElement('path', { d: 'M15 11.5a2.5 2.5 0 0 1 5-5 2.5 2.5 0 0 1-5-5 2.5 2.5 0 0 1-5 5 2.5 2.5 0 0 1 5 5Z' }), React.createElement('path', { d: 'M17.5 22a2.5 2.5 0 0 1-5-5 2.5 2.5 0 0 1 5-5 2.5 2.5 0 0 1 5 5 2.5 2.5 0 0 1-5 5Z' }), React.createElement('path', { d: 'M9.5 12.5a2.5 2.5 0 0 1-5-5 2.5 2.5 0 0 1 5-5 2.5 2.5 0 0 1 5 5 2.5 2.5 0 0 1-5 5Z' }), React.createElement('path', { d: 'M12 13v-1c0-.5.5-1 1-1h.5c.5 0 1-.5 1-1V8c0-.5-.5-1-1-1h-1' }), React.createElement('path', { d: 'M12 13v1c0 .5-.5 1-1 1h-.5c-.5 0-1 .5-1 1V17c0 .5.5 1 1 1h1' })),
            'Gauge': React.createElement('svg', { xmlns: 'http://www.w3.org/2000/svg', width: size, height: size, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', strokeWidth: '2', strokeLinecap: 'round', strokeLinejoin: 'round', className: className }, React.createElement('path', { d: 'm12 14 4-4' }), React.createElement('path', { d: 'M3.34 19.1A8 8 0 1 1 20.7 19.1' }), React.createElement('path', { d: 'M17.76 17.76a7 7 0 1 0-2.52-10.86' }))
        };
        return icons[name] || null;
    };

    return (
        React.createElement("div", { className: "flex h-screen bg-gray-900 text-gray-100" },
            // Sidebar
            React.createElement("div", { className: "chatgpt-sidebar flex flex-col justify-between bg-gray-800 p-4 border-r border-gray-700" },
                React.createElement("div", null,
                    React.createElement("button", { className: "new-chat-button flex items-center justify-center w-full py-2 px-4 rounded-lg text-white font-semibold mb-4", onClick: createNewChatSession },
                        React.createElement(LucideIcon, { name: "MessageSquarePlus", size: 20, className: "mr-2" }),
                        "New chat"
                    ),
                    React.createElement("div", { className: "sidebar-section mb-4" },
                        React.createElement("div", { className: "sidebar-item flex items-center py-2 px-3 rounded-lg text-gray-400 hover:bg-gray-700 cursor-pointer" },
                            React.createElement(LucideIcon, { name: "Search", size: 20, className: "mr-2" }),
                            "Search chats"
                        ),
                        React.createElement("div", { className: "sidebar-item flex items-center py-2 px-3 rounded-lg text-gray-400 hover:bg-gray-700 cursor-pointer" },
                            React.createElement(LucideIcon, { name: "Book", size: 20, className: "mr-2" }),
                            "Library"
                        )
                    ),
                    React.createElement("div", { className: "sidebar-section mb-4" },
                        React.createElement("h3", { className: "text-xs font-semibold text-gray-500 uppercase mb-2" }, "Chats"),
                        chatSessions.map(session => (
                            React.createElement("div", { 
                                key: session.id, 
                                className: `sidebar-item flex items-center py-2 px-3 rounded-lg cursor-pointer ${currentSessionId === session.id ? 'bg-gray-700 text-white' : 'text-gray-400 hover:bg-gray-700'}`, 
                                onClick: () => selectChatSession(session.id)
                            },
                                React.createElement(LucideIcon, { name: "MessageSquareText", size: 20, className: "mr-2" }),
                                session.title
                            )
                        ))
                    )
                ),
                React.createElement("div", { className: "sidebar-bottom" },
                    isDemoMode && (
                        React.createElement("div", { className: "sidebar-item flex items-center py-2 px-3 rounded-lg text-yellow-400 bg-gray-700 mb-2" },
                            React.createElement(LucideIcon, { name: "Sparkles", size: 20, className: "mr-2" }),
                            "Demo Mode"
                        )
                    ),
                    React.createElement("div", { className: "sidebar-item flex items-center py-2 px-3 rounded-lg text-gray-400 hover:bg-gray-700 cursor-pointer" },
                        React.createElement(LucideIcon, { name: "CircleUser", size: 20, className: "mr-2" }),
                        "Upgrade plan"
                    ),
                    React.createElement("div", { className: "sidebar-item flex items-center py-2 px-3 rounded-lg text-gray-400 hover:bg-gray-700 cursor-pointer" },
                        React.createElement(LucideIcon, { name: "LogOut", size: 20, className: "mr-2" }),
                        "Log out"
                    )
                )
            ),

            // Main chat area
            React.createElement("div", { className: "flex-1 flex flex-col bg-gray-900" },
                // Chat header (optional, if needed)
                React.createElement("div", { className: "chat-header p-4 border-b border-gray-700 flex items-center justify-between" },
                    React.createElement("div", { className: "flex items-center" },
                        React.createElement("button", { className: "md:hidden mr-2 text-gray-400 hover:text-white" },
                            React.createElement(LucideIcon, { name: "Menu", size: 24 })
                        ),
                        React.createElement("h2", { className: "text-lg font-semibold text-white" }, currentSessionId ? chatSessions.find(s => s.id === currentSessionId)?.title : "New Chat")
                    ),
                    React.createElement("button", { className: "text-gray-400 hover:text-white" },
                        React.createElement(LucideIcon, { name: "SquarePen", size: 20 })
                    )
                ),

                // Messages display area
                React.createElement("div", { className: "flex-1 overflow-y-auto p-4" },
                    messages.length === 0 ? (
                        React.createElement("div", { className: "flex flex-col items-center justify-center h-full text-gray-400" },
                            React.createElement(LucideIcon, { name: "WandSparkles", size: 48, className: "mb-4" }),
                            React.createElement("h1", { className: "text-2xl font-semibold mb-2" }, "What can I help with?"),
                            React.createElement("div", { className: "grid grid-cols-1 md:grid-cols-2 gap-4 w-full max-w-2xl mt-8" },
                                React.createElement("div", { className: "bg-gray-800 p-4 rounded-lg cursor-pointer hover:bg-gray-700" },
                                    React.createElement("p", { className: "font-semibold" }, "Explain Lua 5.4"),
                                    React.createElement("p", { className: "text-sm text-gray-500" }, "Concepts, syntax, and best practices.")
                                ),
                                React.createElement("div", { className: "bg-gray-800 p-4 rounded-lg cursor-pointer hover:bg-gray-700" },
                                    React.createElement("p", { className: "font-semibold" }, "Perception.cx API"),
                                    React.createElement("p", { className: "text-sm text-gray-500" }, "How to use its functions and features.")
                                ),
                                React.createElement("div", { className: "bg-gray-800 p-4 rounded-lg cursor-pointer hover:bg-gray-700" },
                                    React.createElement("p", { className: "font-semibold" }, "Code a simple script"),
                                    React.createElement("p", { className: "text-sm text-gray-500" }, "For a specific task using Lua 5.4 and Perception.cx.")
                                ),
                                React.createElement("div", { className: "bg-gray-800 p-4 rounded-lg cursor-pointer hover:bg-gray-700" },
                                    React.createElement("p", { className: "font-semibold" }, "Debug a Lua snippet"),
                                    React.createElement("p", { className: "text-sm text-gray-500" }, "Find errors and suggest improvements.")
                                )
                            )
                        )
                    ) : (
                        messages.map((message, index) => (
                            React.createElement("div", { key: index, className: `flex items-start mb-4 ${message.sender === 'user' ? 'justify-end' : 'justify-start'}` },
                                message.sender === 'ai' && (
                                    React.createElement("div", { className: "flex-shrink-0 w-8 h-8 rounded-full bg-blue-500 flex items-center justify-center mr-3" },
                                        React.createElement(LucideIcon, { name: "Bot", size: 20, className: "text-white" })
                                    )
                                ),
                                React.createElement("div", { className: `message-bubble p-3 rounded-lg max-w-[70%] ${message.sender === 'user' ? 'bg-blue-600 text-white' : 'bg-gray-700 text-gray-100'}` },
                                    renderMessageContent(message.text)
                                ),
                                message.sender === 'user' && (
                                    React.createElement("div", { className: "flex-shrink-0 w-8 h-8 rounded-full bg-gray-600 flex items-center justify-center ml-3" },
                                        React.createElement(LucideIcon, { name: "User", size: 20, className: "text-white" })
                                    )
                                )
                            )
                        ))
                    )
                ),
                messages.length > 0 && React.createElement("div", { ref: messagesEndRef }), // Scroll anchor

                // Input area
                React.createElement("form", { className: "chat-input-area p-4 bg-gray-800 border-t border-gray-700 flex items-center", onSubmit: handleSendMessage },
                    React.createElement("button", { type: "button", className: "p-2 text-gray-400 hover:text-white mr-2" },
                        React.createElement(LucideIcon, { name: "PlusCircle", size: 24 })
                    ),
                    React.createElement("input", {
                        type: "text",
                        className: "flex-1 bg-gray-700 text-white px-4 py-2 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500",
                        placeholder: loading ? "Generating response..." : "Message Perception AI...",
                        value: input,
                        onChange: (e) => setInput(e.target.value),
                        disabled: loading
                    }),
                    React.createElement("button", { type: "button", className: "p-2 text-gray-400 hover:text-white ml-2" },
                        React.createElement(LucideIcon, { name: "Mic", size: 24 })
                    ),
                    React.createElement("button", { type: "submit", className: `p-2 rounded-lg ml-2 ${loading ? 'bg-gray-600 cursor-not-allowed' : 'bg-blue-600 hover:bg-blue-700'}`,
                        disabled: loading
                    },
                        React.createElement(LucideIcon, { name: "SendHorizonal", size: 24, className: "text-white" })
                    )
                )
            )
        )
    );
};

ReactDOM.render(React.createElement(App, null), document.getElementById('root'));

