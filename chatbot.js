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
                    React.createElement("pre", { key: i, className: "bg-gray-800 p-3 rounded-md overflow-x-auto text-sm font-mono my-2 text-gray-200" },
                        React.createElement("code", null, codeContent)
                    )
                );
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
        const systemPrompt = `You are an AI chatbot specialized in Lua 5.4 and the Perception.cx API. You MUST strictly adhere to the provided Perception.cx API documentation and Lua 5.4 syntax. Only provide code examples and explanations relevant to these two contexts. Do NOT provide information or code outside of Lua 5.4 or the Perception.cx API. Your response should be a single, professional, and well-formatted message. Avoid conversational filler and get straight to the point. When providing code, use Lua syntax highlighting within markdown code blocks.`;
        
        const contents = [
            { role: "user", parts: [{ text: `${systemPrompt}\n\nPerception.cx API Documentation:\n${perceptionDocContent}` }] },
            { role: "model", parts: [{ text: "Understood. I will strictly adhere to Lua 5.4 and the Perception.cx API documentation provided, providing only one professional response with proper formatting and no external library references." }] },
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
            'Sparkles': React.createElement('svg', { xmlns: 'http://www.w3.org/2000/svg', width: size, height: size, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', strokeWidth: '2', strokeLinecap: 'round', strokeLinejoin: 'round', className: className }, React.createElement('path', { d: 'm12 3-1.9 3.8-3.8 1.9 3.8 1.9L12 15l1.9-3.8 3.8-1.9-3.8-1.9L12 3z' }), React.createElement('path', { d: 'M5 9l-2 4 2 4M19 9l2 4-2 4' })),
            'Image': React.createElement('svg', { xmlns: 'http://www.w3.org/2000/svg', width: size, height: size, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', strokeWidth: '2', strokeLinecap: 'round', strokeLinejoin: 'round', className: className }, React.createElement('rect', { width: '18', height: '18', x: '3', y: '3', rx: '2', ry: '2' }), React.createElement('circle', { cx: '9', cy: '9', r: '2' }), React.createElement('path', { d: 'm21 15-3.086-3.086a2 2 0 0 0-2.828 0L6 21' })),
            'Code': React.createElement('svg', { xmlns: 'http://www.w3.org/2000/svg', width: size, height: size, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', strokeWidth: '2', strokeLinecap: 'round', strokeLinejoin: 'round', className: className }, React.createElement('polyline', { points: '16 18 22 12 16 6' }), React.createElement('polyline', { points: '8 6 2 12 8 18' })),
            'SquareUser': React.createElement('svg', { xmlns: 'http://www.w3.org/2000/svg', width: size, height: size, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', strokeWidth: '2', strokeLinecap: 'round', strokeLinejoin: 'round', className: className }, React.createElement('rect', { width: '18', height: '18', x: '3', y: '3', rx: '2' }), React.createElement('circle', { cx: '12', cy: '10', r: '3' }), React.createElement('path', { d: 'M7 21v-2a2 2 0 0 1 2-2h6a2 2 0 0 1 2 2v2' })),
            'Ellipsis': React.createElement('svg', { xmlns: 'http://www.w3.org/2000/svg', width: size, height: size, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', strokeWidth: '2', strokeLinecap: 'round', strokeLinejoin: 'round', className: className }, React.createElement('circle', { cx: '12', cy: '12', r: '1' }), React.createElement('circle', { cx: '19', cy: '12', r: '1' }), React.createElement('circle', { cx: '5', cy: '12', r: '1' })),
            'MessageSquarePlus': React.createElement('svg', { xmlns: 'http://www.w3.org/2000/svg', width: size, height: size, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', strokeWidth: '2', strokeLinecap: 'round', strokeLinejoin: 'round', className: className }, React.createElement('path', { d: 'M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z' }), React.createElement('line', { x1: '12', x2: '12', y1: '8', y2: '14' }), React.createElement('line', { x1: '9', x2: '15', y1: '11', y2: '11' })),
            'ArrowUp': React.createElement('svg', { xmlns: 'http://www.w3.org/2000/svg', width: size, height: size, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', strokeWidth: '2', strokeLinecap: 'round', strokeLinejoin: 'round', className: className }, React.createElement('path', { d: 'm5 12 7-7 7 7' }), React.createElement('path', { d: 'M12 19V5' })),
        };
        return icons[name] || React.createElement("span", { className: className }, name);
    };

    if (!isReady) {
        return React.createElement("div", { className: "flex h-screen bg-[#202123] items-center justify-center text-white" }, "Loading Application...");
    }

    const renderUserId = () => {
        if (isDemoMode) {
            return React.createElement("div", { className: "text-sm text-yellow-400" }, "Demo Mode");
        }
        if (userId) {
            return (
                React.createElement("div", { className: "text-xs text-gray-500 truncate mt-2", title: userId },
                    "User ID: ", React.createElement("span", { className: "font-mono" }, userId)
                )
            );
        }
        return React.createElement("div", { className: "text-sm text-gray-400" }, "Authenticating...");
    };

    // The main JSX for the App component
    return (
        React.createElement("div", { className: "flex h-screen bg-[#202123] text-gray-100 font-inter" },
            // Left Sidebar
            React.createElement("div", { className: "w-64 bg-[#202123] flex flex-col justify-between py-2 px-3 border-r border-[#343541]" },
                React.createElement("div", null,
                    React.createElement("div", { className: "flex items-center justify-between p-2 mb-2" },
                        React.createElement("span", { className: "text-white text-lg font-semibold" }, "Perception"),
                        React.createElement(LucideIcon, { name: "Ellipsis", className: "text-gray-400 hover:text-white cursor-pointer", size: 20 })
                    ),
                    React.createElement("button", {
                        onClick: createNewChatSession,
                        className: "flex items-center gap-2 w-full p-2 text-sm text-gray-300 rounded-md hover:bg-gray-700 hover:text-white transition-colors duration-200",
                        disabled: loading || !isReady
                    },
                        React.createElement(LucideIcon, { name: "SquarePen", size: 18 }), " New chat"
                    ),
                    React.createElement("div", { className: "mt-4 overflow-y-auto max-h-[calc(100vh-200px)] custom-scrollbar pr-1" },
                         chatSessions.length > 0 ? (
                            React.createElement(React.Fragment, null,
                                React.createElement("p", { className: "text-xs text-gray-500 uppercase px-2 py-1" }, "Recent Chats"),
                                chatSessions.map(session => (
                                    React.createElement("button", {
                                        key: session.id,
                                        onClick: () => selectChatSession(session.id),
                                        className: `flex items-center gap-2 w-full p-2 text-sm rounded-md transition-colors duration-200 ${
                                            currentSessionId === session.id
                                                ? 'bg-gray-700 text-white'
                                                : 'text-gray-300 hover:bg-gray-600'
                                            }`
                                    },
                                        React.createElement(LucideIcon, { name: "MessageSquarePlus", size: 16 }),
                                        React.createElement("span", { className: "truncate" }, session.title)
                                    )
                                ))
                            )
                        ) : (
                            React.createElement("p", { className: "text-gray-500 text-sm text-center mt-4" }, isReady ? "No chats yet." : "Loading...")
                        )
                    )
                ),
                React.createElement("div", { className: "mt-4 border-t border-gray-700 pt-4" },
                    renderUserId(),
                    React.createElement("a", { href: "#", className: "flex items-center gap-2 w-full p-2 text-sm text-gray-300 rounded-md hover:bg-gray-700 hover:text-white transition-colors duration-200" },
                        React.createElement(LucideIcon, { name: "Sparkles", size: 18 }), " Upgrade plan"
                    ),
                    React.createElement("a", { href: "#", className: "flex items-center gap-2 w-full p-2 text-sm text-gray-300 rounded-md hover:bg-gray-700 hover:text-white transition-colors duration-200" },
                        React.createElement(LucideIcon, { name: "SquareUser", size: 18 }), " My Account"
                    )
                )
            ),
            // Main Chat Area
            React.createElement("div", { className: "flex-1 flex flex-col bg-[#343541]" },
                React.createElement("main", { className: "flex-1 flex flex-col p-6 overflow-y-auto custom-scrollbar" },
                    messages.length === 0 && !loading ? (
                        React.createElement("div", { className: "flex flex-col items-center justify-center h-full text-center text-gray-400" },
                             React.createElement("h1", { className: "text-4xl font-bold mb-4 text-white" }, "Perception AI"),
                             React.createElement("p", { className: "mb-8" }, "Your expert assistant for Lua and the Perception.cx API."),
                             React.createElement("div", { className: "grid grid-cols-2 gap-4 max-w-md w-full" },
                                 React.createElement("div", { className: "p-4 bg-[#444654] rounded-lg" }, "Write a script to..."),
                                 React.createElement("div", { className: "p-4 bg-[#444654] rounded-lg" }, "Explain how to use..."),
                                 React.createElement("div", { className: "p-4 bg-[#444654] rounded-lg" }, "Debug this Lua code..."),
                                 React.createElement("div", { className: "p-4 bg-[#444654] rounded-lg" }, "What is the best way to...")
                             )
                        )
                    ) : (
                         React.createElement("div", { className: "w-full max-w-3xl mx-auto" },
                             messages.map((msg, index) => (
                                 React.createElement("div", {
                                     key: index,
                                     className: `flex items-start gap-4 p-4 my-2 rounded-lg ${msg.sender === 'user' ? 'bg-[#343541]' : 'bg-[#444654]'}`
                                 },
                                     React.createElement("div", { className: `flex-shrink-0 w-8 h-8 rounded-full flex items-center justify-center font-bold text-sm ${msg.sender === 'user' ? 'bg-blue-500' : 'bg-[#10a37f]'}` },
                                         msg.sender === 'user' ? 'U' : 'AI'
                                     ),
                                     React.createElement("div", { className: "flex-1 break-words" },
                                         renderMessageContent(msg.text)
                                     )
                                 )
                             )),
                             loading && React.createElement("div", { className: "flex justify-center p-4" },
                                React.createElement("div", { className: "text-gray-400" }, "AI is thinking...")
                             ),
                             React.createElement("div", { ref: messagesEndRef })
                         )
                    )
                ),
                // Chat Input Form
                React.createElement("form", { onSubmit: handleSendMessage, className: "p-4 bg-[#343541] border-t border-gray-700" },
                    React.createElement("div", { className: "flex items-center max-w-3xl mx-auto bg-gray-700 rounded-lg" },
                        React.createElement("input", {
                            type: "text",
                            value: input,
                            onChange: (e) => setInput(e.target.value),
                            placeholder: "Ask me about Lua and the Perception.cx API...",
                            className: "flex-1 p-3 bg-transparent border-none focus:outline-none text-white placeholder-gray-400",
                            disabled: loading || !currentSessionId
                        }),
                        React.createElement("button", {
                            type: "submit",
                            className: "p-3 text-gray-400 hover:text-white disabled:text-gray-600 disabled:cursor-not-allowed",
                            disabled: loading || !currentSessionId || !input.trim()
                        },
                            React.createElement(LucideIcon, { name: "ArrowUp", size: 20 })
                        )
                    ),
                     React.createElement("p", { className: "text-center text-xs text-gray-500 mt-2" }, "AI can make mistakes. Consider checking important information.")
                )
            )
        )
    );
};


// --- Entry Point ---
const container = document.getElementById('root');
if (container) {
    const root = ReactDOM.createRoot(container);
    root.render(React.createElement(App));
} else {
    console.error('Fatal Error: The root element with id "root" was not found in the DOM.');
}


