// Removed direct import for React and ReactDOM, relying on them being global from index.html
const { useState, useEffect, useRef } = React; // Destructure directly from global React

// Firebase imports remain as modules from CDN
import { initializeApp } from 'https://www.gstatic.com/firebasejs/11.6.1/firebase-app.js';
import { getAuth, signInAnonymously, signInWithCustomToken, onAuthStateChanged } from 'https://www.gstatic.com/firebasejs/11.6.1/firebase-auth.js';
import { getFirestore, collection, addDoc, onSnapshot, query, orderBy, doc, getDoc, updateDoc, setDoc } from 'https://www.gstatic.com/firebasejs/11.6.1/firebase-firestore.js';

// Main App component
const App = () => {
    const [messages, setMessages] = useState([]);
    const [input, setInput] = useState('');
    const [loading, setLoading] = useState(false);
    const [db, setDb] = useState(null);
    const [auth, setAuth] = useState(null);
    const [userId, setUserId] = useState(null);
    const [chatSessions, setChatSessions] = useState([]);
    const [currentSessionId, setCurrentSessionId] = useState(null);
    const messagesEndRef = useRef(null);
    const [isAuthReady, setIsAuthReady] = useState(false); // New state to track auth readiness

    // Scroll to the latest message whenever messages update
    useEffect(() => {
        messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
    }, [messages]);

    // Initialize Firebase and handle authentication
    useEffect(() => {
        try {
            const firebaseConfig = typeof __firebase_config !== 'undefined' ? JSON.parse(__firebase_config) : {};
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
                    // Sign in anonymously if no token is provided
                    try {
                        if (typeof __initial_auth_token !== 'undefined') {
                            await signInWithCustomToken(firebaseAuth, __initial_auth_token);
                        } else {
                            await signInAnonymously(firebaseAuth);
                        }
                    } catch (error) {
                        console.error("Firebase Auth Error:", error);
                    }
                }
                setIsAuthReady(true); // Set auth ready once initial check is done
            });

            return () => unsubscribe(); // Cleanup auth listener on unmount
        } catch (error) {
            console.error("Failed to initialize Firebase:", error);
        }
    }, []);

    // Fetch chat sessions when auth is ready and userId is available
    useEffect(() => {
        if (!isAuthReady || !db || !userId) return;

        const chatSessionsRef = collection(db, `artifacts/${__app_id}/users/${userId}/chatSessions`);
        const q = query(chatSessionsRef, orderBy('updatedAt', 'desc'));

        const unsubscribe = onSnapshot(q, (snapshot) => {
            const sessions = snapshot.docs.map(doc => ({
                id: doc.id,
                ...doc.data()
            }));
            setChatSessions(sessions);

            // If no current session is selected, select the most recent one or create a new one
            if (!currentSessionId && sessions.length > 0) {
                setCurrentSessionId(sessions[0].id);
            } else if (!currentSessionId && sessions.length === 0) {
                createNewChatSession();
            }
        }, (error) => {
            console.error("Error fetching chat sessions:", error);
        });

        return () => unsubscribe();
    }, [isAuthReady, db, userId, currentSessionId]);


    // Fetch messages for the current session
    useEffect(() => {
        if (!isAuthReady || !db || !userId || !currentSessionId) {
            setMessages([]); // Clear messages if no session selected or not ready
            return;
        }

        const sessionDocRef = doc(db, `artifacts/${__app_id}/users/${userId}/chatSessions`, currentSessionId);
        const unsubscribe = onSnapshot(sessionDocRef, (docSnap) => {
            if (docSnap.exists()) {
                setMessages(docSnap.data().messages || []);
            } else {
                setMessages([]);
                console.log("Current session document does not exist.");
            }
        }, (error) => {
            console.error("Error fetching messages for current session:", error);
        });

        return () => unsubscribe();
    }, [isAuthReady, db, userId, currentSessionId]);

    // Create a new chat session
    const createNewChatSession = async () => {
        if (!db || !userId) return;

        setLoading(true);
        try {
            const newSessionRef = await addDoc(collection(db, `artifacts/${__app_id}/users/${userId}/chatSessions`), {
                title: `New Chat ${new Date().toLocaleDateString()}`, // Default title
                messages: [],
                createdAt: new Date(),
                updatedAt: new Date()
            });
            setCurrentSessionId(newSessionRef.id);
            setMessages([]); // Clear messages for the new session
        } catch (error) {
            console.error("Error creating new chat session:", error);
        } finally {
            setLoading(false);
        }
    };

    // Helper function to render message content, including code blocks
    const renderMessageContent = (text) => {
        // This regex looks for code blocks: ```[language]\ncode\n```
        const parts = text.split(/(```(?:[a-zA-Z0-9]+)?\n[\s\S]*?\n```)/g);

        return parts.map((part, i) => {
            if (part.startsWith('```')) {
                // Extract the language and code content
                const match = part.match(/```(?:([a-zA-Z0-9]+))?\n([\s\S]*?)\n```/);
                const codeContent = match ? match[2] : part.replace(/```(?:[a-zA-Z0-9]+)?\n|```/g, '');
                // const language = match ? match[1] : ''; // You could use 'language' for syntax highlighting if a library like react-syntax-highlighter was used

                return (
                    React.createElement("pre", { key: i, className: "bg-gray-800 p-3 rounded-md overflow-x-auto text-sm font-mono my-2 text-gray-200" },
                        React.createElement("code", null, codeContent)
                    )
                );
            } else {
                // Render regular text, split by newlines to handle paragraphs
                return React.createElement("p", { key: i, className: "mb-1 last:mb-0" }, part);
            }
        });
    };

    // Simulated function to fetch content from Perception.cx documentation.
    // In a real application, you would use a backend service or a library
    // to scrape/fetch content from the URL or parse the provided PDF.
    const simulateFetchPerceptionDocContent = () => {
        // Expanded hardcoded example representing a broader range of Perception.cx documentation.
        // In a real application, this would be retrieved dynamically.
        // All backticks are now properly escaped with \`
        return `
            ## Perception.cx API Documentation Summary

            **Core Functions (engine):**
            - \`engine.register_on_unload(callback)\`: Registers a function for script unload.
            - \`engine.register_on_engine_tick(callback)\`: Registers a function for every engine tick.
            - \`engine.register_on_network_callback(callback)\`: Handles HTTP network responses.
            - \`engine.log(message, r, g, b, a)\`: Logs messages with color to console.
            - \`engine.get_username()\`: Returns current user's username.

            **Filesystem (fs):**
            - \`fs.does_file_exist(file_name)\`: Checks if a file exists.
            - \`fs.read_from_file(file_name)\`: Reads file content as string.
            - \`fs.write_to_file(file_name, data)\`: Writes string data to file.
            - \`fs.delete_file(file_name)\`: Deletes a file.
            - \`fs.write_to_file_from_buffer(file_name, buffer_handle)\`: Writes buffer to file.
            - \`fs.read_from_file_to_buffer(file_name, buffer_handle)\`: Reads file to buffer.
            - \`fs.get_file_size(file_name)\`: Gets file size in bytes.
            - \`fs.compress(string)\`: Compresses a string.
            - \`fs.decompress(string)\`: Decompresses a string.

            **Input (input):**
            - \`input.simulate_mouse(dx, dy, flag)\`: Simulates mouse input.
            - \`input.simulate_keyboard(key, flag)\`: Simulates keyboard input.
            - \`input.is_key_pressed(key)\`: Detects single key press.
            - \`input.is_key_down(key)\`: Detects if key is held down.
            - \`input.get_mouse_position()\`: Returns mouse X, Y.
            - \`input.get_clipboard()\`: Gets clipboard text.
            - \`input.set_clipboard(text)\`: Sets clipboard text.

            **Rendering (render):**
            - \`render.create_font(font_name, size, weight)\`: Creates a font handle.
            - \`render.get_viewport_size()\`: Retrieves screen dimensions.
            - \`render.draw_line(x1, y1, x2, y2, r, g, b, a, thickness)\`: Draws a line.
            - \`render.draw_rectangle(x, y, width, height, r, g, b, a, thickness, filled)\`: Draws a rectangle.
            - \`render.draw_circle(x, y, radius, r, g, b, a, thickness, filled)\`: Draws a circle.
            - \`render.draw_text(font, text, x, y, r, g, b, a, outline_thickness?, o_r?, o_g?, o_b?, o_a?)\`: Draws text with optional outline.
            - \`render.draw_triangle(x1, y1, x2, y2, x3, y3, r, g, b, a, thickness, filled, rounding?)\`: Draws a triangle.
            - \`render.get_fps()\`: Gets current frames per second.
            - \`render.create_bitmap_from_url(url)\`: Creates bitmap from URL.
            - \`render.create_bitmap_from_buffer(buffer_handle)\`: Creates bitmap from memory buffer.
            - \`render.create_bitmap_from_file(file_name)\`: Creates bitmap from local file.
            - \`render.clip_start(x, y, width, height)\`: Begins a clipping region.
            - \`render.clip_end()\`: Ends clipping region.
            - \`render.draw_gradient_rectangle(...)\`: Draws a four-corner gradient rectangle.
            - \`render.draw_hue_bar(x, y, width, height)\`: Draws a hue gradient bar.

            **GUI (gui):**
            - \`gui.get_tab(name)\`: Retrieves a predefined tab ("aimbot", "visuals", "lua", "settings").
            - \`tab:create_panel(label, small_panel?)\`: Creates a panel in a tab.
            - \`tab:create_subtab(label)\`: Creates a subtab in a tab.
            - \`panel:add_checkbox(label)\`: Adds a checkbox.
            - \`panel:add_slider_int(label, min, max, default)\`: Adds an integer slider.
            - \`panel:add_slider_float(label, min, max, default)\`: Adds a float slider.
            - \`panel:add_button(label, function)\`: Adds a button.
            - \`panel:add_text(label)\`: Adds static text.
            - \`panel:add_input_text(label, default)\`: Adds text input.
            - \`panel:add_color_picker(label, r, g, b, a)\`: Adds a color picker.
            - \`panel:add_keybind(label, key, mode)\`: Adds a keybind.
            - \`panel:add_single_select(label, list, default_index?)\`: Adds a single-select dropdown.
            - \`panel:add_multi_select(label, list)\`: Adds a multi-select list.
            - \`panel:add_singleselect_list(label, list)\`: Adds a single-select list (non-dropdown).
            - \`panel:add_multiselect_list(label, list)\`: Adds a multi-select list (non-dropdown).
            - \`element:set_active(bool)\`: Shows or hides any GUI element.
            - Various methods for getting/setting values for each GUI element type (e.g., \`checkbox:get()\`, \`slider_int:set(value)\`).
            - \`gui.get_state()\`: Serializes GUI state to Base64.
            - \`gui.load_state(string)\`: Loads GUI state from Base64.
            - Keybind Modes: \`key_mode.onhotkey\`, \`key_mode.offhotkey\`, \`key_mode.toggle\`, \`key_mode.singlepress\`, \`key_mode.always_on\`.

            **Memory (m):**
            - \`m.alloc(size)\`: Allocates memory block.
            - \`m.free(handle)\`: Frees memory block.
            - Read/Write functions for various data types: \`m.read_double\`, \`m.write_double\`, \`m.read_float\`, \`m.write_float\`, etc. (for 8, 16, 32, 64-bit integers and strings).
            - \`m.get_size(handle)\`: Returns size of allocated memory buffer.

            **Process (proc):**
            - \`proc.is_attached()\`: Checks if a process is attached.
            - \`proc.did_exit()\`: Checks if attached process exited.
            - \`proc.pid()\`: Returns process ID.
            - \`proc.base_address()\`: Returns base address of attached process.
            - \`proc.find_module(module_name)\`: Finds module address and size.
            - \`proc.find_signature(base_address, size, signature)\`: Searches for memory pattern.
            - Read/Write functions for process memory: \`proc.read_double\`, \`proc.write_double\`, etc. (for floats, doubles, 8, 16, 32, 64-bit integers, and strings/wide strings).
            - \`proc.read_to_memory_buffer(address, buffer, size)\`: Reads process memory into local buffer.
            - \`proc.write_from_memory_buffer(address, buffer, size)\`: Writes local buffer to process memory.
            - Process Attachment: \`proc.attach_by_pid(process_id, has_corrupt_cr3?)\`, \`proc.attach_by_name(process_name, has_corrupt_cr3?)\`, \`proc.attach_by_window(window_class, window_name, has_corrupt_cr3?)\`.

            **Networking (net):**
            - \`net.send_request(url, headers, post_fields)\`: Sends HTTP request.
            - \`net.resolve(hostname)\`: Resolves hostname to IP.
            - \`net.create_socket(ip, port)\`: Opens TCP connection.
            - \`socket:send(data)\`: Sends data on a socket.
            - \`socket:receive(maxlen)\`: Reads data from a socket.
            - \`socket:close()\`: Closes a socket connection.
            - \`net.base64_encode(string)\`: Base64 encodes a string.
            - \`net.base64_decode(string)\`: Base64 decodes a string.

            **String (str):**
            - Trimming: \`str.trim()\`, \`str.ltrim()\`, \`str.rtrim()\`.
            - Padding: \`str.pad_left()\`, \`str.pad_right()\`.
            - Prefix/Suffix: \`str.strip_prefix()\`, \`str.strip_suffix()\`.
            - Search: \`str.startswith()\`, \`str.endswith()\`, \`str.contains()\`, \`str.indexof()\`, \`str.last_indexof()\`, \`str.count()\`, \`str.empty()\`, \`str.equals()\`.
            - Modification: \`str.replace()\`, \`str.repeat_str()\`, \`str.reverse()\`, \`str.insert()\`, \`str.remove()\`, \`str.substitute()\`.
            - Case/Splitting: \`str.upper()\`, \`str.lower()\`, \`str.split()\`, \`str.slice()\`.
            - UTF-8 Support: \`str.utf8len()\`, \`str.utf8sub()\`.

            **JSON (json):**
            - \`json.parse(data)\`: Parses JSON string to Lua table.
            - \`json.stringify(lua_table)\`: Converts Lua table to JSON string.

            **Math (math):**
            - Core: \`math.clamp()\`, \`math.lerp()\`, \`math.round()\`, \`math.round_up()\`, \`math.round_down()\`, \`math.round_to_nearest()\`, \`math.sign()\`, \`math.map()\`, \`math.saturate()\`.
            - Validation: \`math.is_nan()\`, \`math.is_inf()\`.
            - Interpolation: \`math.smoothstep()\`, \`math.inverse_lerp()\`, \`math.fract()\`, \`math.wrap()\`.

            **Time (time):**
            - Current Time: \`time.unix()\`, \`time.unix_ms()\`, \`time.now_utc()\`, \`time.now_local()\`.
            - Formatting: \`time.format(timestamp)\`, \`time.format_custom(timestamp, format)\`.
            - Comparison: \`time.delta()\`, \`time.compare()\`, \`time.same_day()\`, \`time.diff_table()\`, \`time.between()\`.
            - Date Info: \`time.weekday()\`, \`time.day_of_year()\`, \`time.year_month_day()\`, \`time.is_weekend()\`, \`time.is_leap_year()\`, \`time.days_in_month()\`.
            - Conversion: \`time.timestamp_utc()\`, \`time.add_days()\`, \`time.start_of_day()\`, \`time.end_of_day()\`, \`time.to_table()\`, \`time.from_table()\`, \`time.to_utc_table()\`, \`time.from_utc_table()\`.
            - Validation: \`time.is_valid()\`, \`time.is_dst()\`, \`time.utc_offset()\`, \`time.get_timezone()\`.
            - Utilities: \`time.seconds_to_hhmmss()\`.
            - Constants: \`time.SECONDS_PER_MINUTE\`, \`time.SECONDS_PER_HOUR\`, etc.

            **Vector Types (vec2, vec3, vec4):**
            - Constructors: \`vec2(x, y)\`, \`vec3(x, y, z)\`, \`vec4(x, y, z, w)\`.
            - Operators: Addition, Subtraction, Multiplication (scalar), Division (scalar), Negation, Length (\`#vec\`), Equality.
            - Fields: \`.x\`, \`.y\`, (\`.z\` for vec3/4), (\`.w\` for vec4).
            - Methods (common for all, with dimension-specific variations): \`:length()\`, \`:length_squared()\`, \`:normalize()\`, \`:dot(v)\`, \`:distance(v)\`, \`:clone()\`, \`:lerp(v, t)\`.
            - Specific: \`vec2:perpendicular()\`, \`vec2:angle()\`, \`vec2:rotate(radians)\`, \`vec3:cross(v)\`, \`vec3:angle_between(v)\`.
            - Memory Access: \`vecX.read_float(address)\`, \`vecX.write_float(address, v)\` (and double versions).

            **Matrix (mat4):**
            - Constructor: \`mat4()\` (identity matrix).
            - Operators: Multiplication (\`mat4 * mat4\`), Transformation (\`mat4 * vec4\`).
            - Access: \`mat4:get(row, col)\`, \`mat4:set(row, col, value)\`, \`mat4:row(index)\`, \`mat4:column(index)\`.
            - Utility: \`mat4:clone()\`, \`mat4:to_table()\`, \`mat4.from_table(table)\`.
            - Transformations: \`mat4:transpose()\`, \`mat4:inverse()\`, \`mat4:determinant()\`, \`mat4:scale(vec3)\`, \`mat4:translate(vec3)\`, \`mat4:rotate(angle, axis)\`, \`mat4:apply_to_vec3(vec3)\`.
            - Decomposition: \`mat4:decompose()\`.
            - Comparison: \`mat4:equals(other, tolerance?)\`, \`mat4:is_identity()\`.
            - Memory Access: \`mat4.read(address)\`.
            - Special Constructors: \`mat4.perspective()\`, \`mat4.orthographic()\`, \`mat4.trs()\`, \`mat4.look_at()\`.

            **Windows (winapi):**
            - System: \`winapi.get_tickcount64()\`.
            - Audio: \`winapi.play_sound(file_name)\`.
            - Window Handling: \`winapi.get_hwnd(class_name?, window_name?)\`.
            - Message Posting: \`winapi.post_message(hwnd, msg, wparam, lparam)\`.

            **Game Specific APIs (Extended API - Universal Lua API subscription required):**
            - **Marvel Rivals (marvel_rivals):** \`get_local_player()\`, \`get_player_list()\`, \`get_world()\`, \`get_game_instance()\`, \`get_game_state()\`, \`world_to_screen(x, y, z)\`, \`get_bone_position(skeletal_mesh, bone_id)\`, \`get_class_dump(pointer)\`. Includes specific bone IDs.
            - **Counter-Strike 2 (cs2):** \`trace.cast(...)\`, \`get_interface(...)\`, \`get_cvar(...)\`, \`get_entity_list()\`, \`get_entity_system()\`, \`get_highest_entity_index()\`, \`get_global_vars()\`, \`get_game_rules()\`, \`get_planted_c4()\`, \`get_view_matrix()\`, \`world_to_screen(x, y, z)\`, \`get_bone_position(bone_array, bone_id)\`, \`get_player_list()\`, \`get_local_player()\`, \`get_schema_dump()\`.
            - **Valorant (valorant):** \`get_class_dump(pointer)\`.
            - **Fortnite (fortnite):** \`get_player_name(address)\`.
            - **Rust (rust):** \`get_transform_position(address)\`.
            - **PUBG (pubg):** \`init_decrypt(offset)\`, \`xe_decrypt(address)\` (use at your own risk).
            - **Universal Process Functions:** \`proc.attach_by_pid()\`, \`proc.attach_by_name()\`, \`proc.attach_by_window()\`, \`proc.is_attached()\` (some functions repeated for clarity under Universal API).

            **Universal API Information:** Bypasses Easy Anti-Cheat, BattleEye, Neac Protect, VAC, nProtect Game Guard, ACE, EA Anti-Cheat, PAC. **Riot's Vanguard Anti-Cheat and Face-IT are NOT supported.**

            --- Common Lua Scripting Patterns and Perception.cx API Usage Examples (Learned from User-Provided Scripts) ---

            Perception.cx scripts often follow a structured approach to game interaction, typically involving:

            ### 1. Script Lifecycle Management:
            - **Initialization (onLoad):** Setting up global variables, allocating memory buffers (e.g., \`m.alloc\` for vectors or larger data structures), and performing initial process attachment checks (\`proc.attach_by_name\`).
            - **Continuous Updates (engine.register_on_engine_tick):** The core logic runs every game tick. This includes updating game state, reading player/entity data, performing calculations, and drawing visuals.
            - **Cleanup (engine.register_on_unload):** Freeing allocated memory (\`m.free\`), unbinding callbacks, or saving persistent data when the script is stopped.

            ### 2. Process Interaction and Memory Reading:
            - **Attaching to a Game:** Scripts begin by attaching to the target game process, e.g., \`proc.attach_by_name("DayZ_x64.exe")\` or \`proc.attach_by_name("RustClient.exe")\`. They check \`proc.is_attached()\` and \`proc.base_address()\` to ensure a successful attachment.
            - **Reading Game Data:** Extensive use of \`proc.read_int64\`, \`proc.read_float\`, \`proc.read_string\`, and vector type-specific 'read_float'/'read_double' methods (e.g., \`vec2.read_float\`, \`vec3.read_float\`, \`vec4.read_float\`, etc.) to access game-specific pointers, values (health, position), and strings from the attached process'ss memory.
            - **Memory Structures and Offsets:** Scripts define tables of hexadecimal offsets (e.g., \`gameOffsets\`, \`OFFSETS\`) to navigate complex in-game data structures (World, Camera, PlayerList, EntityList, specific player properties, bone arrays). They often chain reads through pointers.
            - **Error Handling for Memory Reads:** Common pattern to check for \`nil\` or \`0\` return values from memory read functions (e.g., \`if (address == nil or address == 0) then goto skipEntity; end;\`) to prevent crashes.

            ### 3. UI and Configuration (GUI Module):
            - **Menu Creation:** Using \`gui.get_tab\` to access predefined tabs (e.g., "visuals", "aimbot", "settings", "lua"), and then \`tab:create_panel\` and \`tab:create_subtab\` to organize UI elements.
            - **Adding Widgets:** Employing \`panel:add_checkbox\`, \`panel:add_slider_int\`, \`panel:add_slider_float\`, \`panel:add_keybind\`, \`panel:add_color_picker\`, \`panel:add_single_select\`, \`panel:add_multi_select\`, \`panel:add_button\`, \`panel:add_input_text\` to build interactive menus.
            - **Reading/Writing Widget States:** Using methods like \`element:get()\` to retrieve the current state of a UI element (e.g., checkbox state, slider value, selected option) and \`element:set(value)\` to programmatically change it.
            - **Keybind Handling:** Keybinds are frequently configured using \`key_mode.onhotkey\` (active while held), \`key_mode.toggle\` (switches state on press), and are checked with \`keybind:is_active()\` or \`input.is_key_down()\`.
            - **Configuration Persistence:** Scripts use \`gui.get_state()\` to serialize the entire GUI state to a Base64 string and \`fs.write_to_file()\` to save it to a \`.cfg\` file. \`fs.read_from_file()\` and \`gui.load_state()\` are used to load saved configurations. JSON (\`json.stringify\`, \`json.parse\`) is used for structured data within configs.

            ### 4. Rendering and Visuals (render module):
            - **Screen Dimensions:** \`render.get_viewport_size()\` is commonly used to get the screen width and height for responsive UI and ESP calculations.
            - **Font Management:** \`render.create_font()\` for custom text styles.
            - **Drawing Primitives:** \`render.draw_text\`, \`render.draw_rectangle\`, \`render.draw_circle\`, \`render.draw_line\`, \`render.draw_triangle\` are used extensively for ESP (Extra Sensory Perception) features like player boxes, names, health bars, distances, skeletons, FOV circles, and OOF (Out Of View) indicators.
            - **Coordinate Transformation:** Game-specific \`world_to_screen\` functions (e.g., \`marvel_rivals.world_to_screen\`, \`cs2.world_to_screen\`, custom implementations) convert 3D in-game coordinates to 2D screen coordinates for drawing. This often involves matrix transformations (\`mat4\`).
            - **Conditional Rendering:** Visuals are frequently drawn only if certain checkboxes are enabled, keybinds are active, or entities meet specific criteria (e.g., distance, visibility).
            - **Dynamic Sizing/Opacity:** Values like font size, box dimensions, and element opacity are often scaled based on in-game distance for better visual appeal and information density.

            ### 5. Game Logic and Calculations (Math, Vector modules, custom SDK):
            - **Vector Mathematics:** Extensive use of \`vec2\`, \`vec3\` types for positions, velocities, and directions. Operations like \`add\`, \`subtract\`, \`multiply\`, \`dot\`, \`distance\`, \`normalize\` are fundamental for ESP calculations (distance, screen positioning) and Aimbot (angle calculation, prediction).
            - **Matrix Transformations (mat4):** \`mat4\` is crucial for \`world_to_screen\` conversions, representing camera views, and entity transformations. Matrix multiplication (\`mat4 * mat4\`, \`mat4 * vec4\`) is used for combining transformations.
            - **Aimbot Logic:** Involves calculating angles between player and target, smoothing mouse movement (\`math.lerp\`), predicting target positions based on velocity and projectile physics, and simulating mouse input (\`input.simulate_mouse\`). Hitbox selection (head, body, nearest) and FOV checks are common.
            - **Prediction:** Complex calculations involving \`projectileVelocity\`, \`gravityModifier\`, and \`drag\` to estimate where a target will be when a projectile hits, often leveraging \`math.clamp\`, \`math.lerp\`.
            - **Recoil Control:** Modifying in-game recoil properties (e.g., \`yawMin\`, \`yawMax\`, \`pitchMin\`, \`pitchMax\`) through memory writes (\`proc.write_float\`). This often involves reading the original values, applying a multiplier, and restoring them.
            - **Player State Flags:** Reading and manipulating player state flags (e.g., \`playerFlags\`, \`modelStateFlags\`) to detect sleeping, knocked, aiming, or admin status.

            ### 6. Networking & External Communication:
            - **HTTP Requests:** \`net.send_request\` is used to communicate with external web servers (e.g., for "web radar" features, sending script load/unload notifications, or fetching game data/configs).
            - **Asynchronous Responses:** \`engine.register_on_network_callback\` is vital for handling responses from \`net.send_request\`, which are asynchronous. Responses are typically received as memory buffers that need to be read (e.g., \`m.read_string\`) and potentially parsed (e.g., \`json.parse\`).
            - **Data Serialization:** \`json.stringify\` and \`json.parse\` are used to convert Lua tables to JSON strings and vice-versa for sending/receiving structured data over HTTP or saving to files.
            - **Base64 Encoding/Decoding:** \`net.base64_encode\` and \`net.base64_decode\` are used for transmitting data safely or as part of encryption schemes.

            ### 7. Utility and General Lua Patterns:
            - **Table Manipulation:** Frequent use of Lua tables for data structures (offsets, player lists, UI elements, configurations). \`table.insert\`, \`table.remove\`, and iterating with \`pairs\` and \`ipairs\` are common.
            - **Conditional Logic & Loops:** Extensive \`if/else\`, \`while\`, and \`for\` loops for game logic, entity iteration, and UI drawing.
            - **Error Safety (\`pcall\`, \`nil\` checks):** Scripts often wrap critical or potentially failing operations (like \`proc.read_*\` functions) in \`pcall\` or use explicit \`nil\`/\`0\` checks to prevent script crashes if memory addresses are invalid or data is not found.
            - **\`goto\` Statements:** Some older or specific game scripts use \`goto\` for efficient skipping of entities in large loops (e.g., \`::skipEntity::\`). This is a Lua feature.
            - **Timers:** Custom timer objects (e.g., \`timer.new()\`) built on \`winapi.get_tickcount64()\` are used to control update rates for various features and prevent excessive resource usage.

            --- End Common Lua Scripting Patterns and Perception.cx API Usage Examples (Learned from User-Provided Scripts) ---
        `;
    };

    // Handle sending a message
    const handleSendMessage = async (e) => {
        e.preventDefault();
        if (!input.trim() || loading || !db || !userId || !currentSessionId) return;

        const userMessage = { sender: 'user', text: input.trim(), timestamp: new Date() };
        const updatedMessages = [...messages, userMessage];
        setMessages(updatedMessages);
        setInput('');
        setLoading(true);

        try {
            // Update the current session in Firestore
            const sessionDocRef = doc(db, `artifacts/${__app_id}/users/${userId}/chatSessions`, currentSessionId);
            await updateDoc(sessionDocRef, {
                messages: updatedMessages,
                updatedAt: new Date()
            });

            let chatHistoryForModel = [];

            // Base system prompt
            const baseSystemPrompt = `You are an AI chatbot specialized in Lua 5.4 programming language and the Perception.cx API.
            Your responses must strictly adhere to information available in Lua 5.4 documentation and the Perception.cx API.
            Do not provide information outside of these two specific topics.
            If you are asked a question that is outside your scope, please state politely that you cannot answer it as it is beyond your specialized knowledge.`;

            // Fetch simulated Perception.cx documentation content
            const perceptionDocContent = simulateFetchPerceptionDocContent();

            // Combine system prompt and fetched content for the model's context
            // The combined context is always present for the first message.
            const fullContextForModel = `${baseSystemPrompt}\n\n--- Start Perception.cx Documentation Context ---\n${perceptionDocContent}\n--- End Perception.cx Documentation Context ---`;

            // If it's the very first message in the session, prepend system instructions AND fetched content to the user's message
            if (messages.length === 0) {
                chatHistoryForModel.push({
                    role: 'user',
                    parts: [{ text: fullContextForModel + "\n\nUser Query: " + userMessage.text }]
                });
            } else {
                // For subsequent messages, include previous messages and the new user message.
                // The AI is expected to retain the context from the first message in this simplified setup.
                // A more advanced RAG would retrieve relevant docs for each turn.
                chatHistoryForModel = updatedMessages.map(msg => ({
                    role: msg.sender === 'user' ? 'user' : 'model',
                    parts: [{ text: msg.text }]
                }));
            }


            const payload = {
                contents: chatHistoryForModel,
                generationConfig: {
                    // You can add more generation configs here if needed, e.g., temperature, top_p, etc.
                }
            };

            // Your Gemini API key
            const apiKey = "AIzaSyA3Zhw-Apw21X2AI6cLQWZU7LGttcqhNlE";

            const apiUrl = `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=${apiKey}`;

            const response = await fetch(apiUrl, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(payload)
            });

            let aiResponseText = "Sorry, I couldn't get a response from the AI.";

            if (!response.ok) {
                const errorBody = await response.text();
                console.error(`AI API Error: HTTP Status ${response.status} - ${response.statusText}`, errorBody);

                if (response.status === 401) {
                    aiResponseText = "Error: Unauthorized. Please ensure your Gemini API key is correctly configured.";
                } else {
                    aiResponseText = `Error from AI: HTTP Status ${response.status}. Please try again later.`;
                }
            } else {
                try {
                    const result = await response.json();
                    if (result.candidates && result.candidates.length > 0 &&
                        result.candidates[0].content && result.candidates[0].content.parts &&
                        result.candidates[0].content.parts.length > 0) {
                        aiResponseText = result.candidates[0].content.parts[0].text;
                    } else if (result.error) {
                        console.error("AI API Error:", result.error.message);
                        aiResponseText = `Error from AI: ${result.error.message}`;
                    } else {
                        console.error("AI API Response structure unexpected:", result);
                        aiResponseText = "Sorry, the AI returned an unexpected response format.";
                    }
                } catch (jsonError) {
                    const rawText = await response.text();
                    console.error("Error parsing AI API response JSON:", jsonError, "Raw response:", rawText);
                    aiResponseText = "Sorry, I received an unreadable response from the AI. Please try again.";
                }
            }

            const aiMessage = { sender: 'ai', text: aiResponseText, timestamp: new Date() };
            const finalMessages = [...updatedMessages, aiMessage];
            setMessages(finalMessages);

            // Update messages in Firestore again with AI response
            await updateDoc(sessionDocRef, {
                messages: finalMessages,
                updatedAt: new Date()
            });

        } catch (error) {
            console.error("Error sending message to AI or updating Firestore:", error);
            const errorMessage = { sender: 'ai', text: 'An unexpected error occurred while processing your request. Please check your console for details.', timestamp: new Date() };
            setMessages((prevMessages) => [...prevMessages, errorMessage]);
        } finally {
            setLoading(false);
        }
    };

    // Placeholder for Lucide icons (replace with actual imports if needed)
    const LucideIcon = ({ name, size = 20, className = '' }) => {
        const icons = {
            'SquarePen': React.createElement('svg', { xmlns: '[http://www.w3.org/2000/svg](http://www.w3.org/2000/svg)', width: size, height: size, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', strokeWidth: '2', strokeLinecap: 'round', strokeLinejoin: 'round', className: className }, React.createElement('path', { d: 'M12 20h9' }), React.createElement('path', { d: 'M16.5 3.5a2.12 2.12 0 0 1 3 3L7 19l-4 1 1-4Z' })),
            'Search': React.createElement('svg', { xmlns: '[http://www.w3.org/2000/svg](http://www.w3.org/2000/svg)', width: size, height: size, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', strokeWidth: '2', strokeLinecap: 'round', strokeLinejoin: 'round', className: className }, React.createElement('circle', { cx: '11', cy: '11', r: '8' }), React.createElement('path', { d: 'm21 21-4.3-4.3' })),
            'Library': React.createElement('svg', { xmlns: '[http://www.w3.org/2000/svg](http://www.w3.org/2000/svg)', width: size, height: size, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', strokeWidth: '2', strokeLinecap: 'round', strokeLinejoin: 'round', className: className }, React.createElement('path', { d: 'm16 6 4 14' }), React.createElement('path', { d: 'M12 6v14' }), React.createElement('path', { d: 'M8 8v12' }), React.createElement('path', { d: 'M4 4v16' })),
            'Sparkles': React.createElement('svg', { xmlns: '[http://www.w3.org/2000/svg](http://www.w3.org/2000/svg)', width: size, height: size, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', strokeWidth: '2', strokeLinecap: 'round', strokeLinejoin: 'round', className: className }, React.createElement('path', { d: 'M9.9 10.9a2 2 0 0 0 0 2.2l4.9 4.9c.8.8 2 .8 2.8 0l2.8-2.8c.8-.8.8-2 0-2.8L12.7 8.1a2 2 0 0 0-2.2 0L5.3 3.7c-.8-.8-2-.8-2.8 0L.5 6.5c-.8.8-.8 2 0 2.8L5.3 14.1a2 2 0 0 0 0 2.2l4.9 4.9c.8.8 2 .8 2.8 0l2.8-2.8c.8-.8.8-2 0-2.8L12.7 8.1a2 2 0 0 0-2.2 0L5.3 3.7c-.8-.8-2-.8-2.8 0L.5 6.5c-.8.8-.8 2 0 2.8L5.3 14.1z' })),
            'Image': React.createElement('svg', { xmlns: '[http://www.w3.org/2000/svg](http://www.w3.org/2000/svg)', width: size, height: size, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', strokeWidth: '2', strokeLinecap: 'round', strokeLinejoin: 'round', className: className }, React.createElement('rect', { width: '18', height: '18', x: '3', y: '3', rx: '2', ry: '2' }), React.createElement('circle', { cx: '9', cy: '9', r: '2' }), React.createElement('path', { d: 'm21 15-3.086-3.086a2 2 0 0 0-2.828 0L6 21' })),
            'Code': React.createElement('svg', { xmlns: '[http://www.w3.org/2000/svg](http://www.w3.org/2000/svg)', width: size, height: size, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', strokeWidth: '2', strokeLinecap: 'round', strokeLinejoin: 'round', className: className }, React.createElement('polyline', { points: '16 18 22 12 16 6' }), React.createElement('polyline', { points: '8 6 2 12 8 18' })),
            'Mic': React.createElement('svg', { xmlns: '[http://www.w3.org/2000/svg](http://www.w3.org/2000/svg)', width: size, height: size, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', strokeWidth: '2', strokeLinecap: 'round', strokeLinejoin: 'round', className: className }, React.createElement('path', { d: 'M12 2a3 3 0 0 0-3 3v7a3 3 0 0 0 6 0V5a3 3 0 0 0-3-3Z' }), React.createElement('path', { d: 'M19 10v2a7 7 0 0 1-14 0v-2' }), React.createElement('line', { x1: '12', x2: '12', y1: '19', y2: '22' })),
            'ChevronRight': React.createElement('svg', { xmlns: '[http://www.w3.org/2000/svg](http://www.w3.org/2000/svg)', width: size, height: size, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', strokeWidth: '2', strokeLinecap: 'round', strokeLinejoin: 'round', className: className }, React.createElement('path', { d: 'm9 18 6-6-6-6' })),
            'SquareUser': React.createElement('svg', { xmlns: '[http://www.w3.org/2000/svg](http://www.w3.org/2000/svg)', width: size, height: size, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', strokeWidth: '2', strokeLinecap: 'round', strokeLinejoin: 'round', className: className }, React.createElement('rect', { width: '18', height: '18', x: '3', y: '3', rx: '2' }), React.createElement('circle', { cx: '12', cy: '10', r: '3' }), React.createElement('path', { d: 'M7 21v-2a2 2 0 0 1 2-2h6a2 2 0 0 1 2 2v2' })),
            'Ellipsis': React.createElement('svg', { xmlns: '[http://www.w3.org/2000/svg](http://www.w3.org/2000/svg)', width: size, height: size, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', strokeWidth: '2', strokeLinecap: 'round', strokeLinejoin: 'round', className: className }, React.createElement('circle', { cx: '12', cy: '12', r: '1' }), React.createElement('circle', { cx: '19', cy: '12', r: '1' }), React.createElement('circle', { cx: '5', cy: '12', r: '1' })),
            'MessageSquarePlus': React.createElement('svg', { xmlns: '[http://www.w3.org/2000/svg](http://www.w3.org/2000/svg)', width: size, height: size, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', strokeWidth: '2', strokeLinecap: 'round', strokeLinejoin: 'round', className: className }, React.createElement('path', { d: 'M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z' }), React.createElement('line', { x1: '12', x2: '12', y1: '8', y2: '14' }), React.createElement('line', { x1: '9', x2: '15', y1: '11', y2: '11' })),
            'ArrowUp': React.createElement('svg', { xmlns: '[http://www.w3.org/2000/svg](http://www.w3.org/2000/svg)', width: size, height: size, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', strokeWidth: '2', strokeLinecap: 'round', strokeLinejoin: 'round', className: className }, React.createElement('path', { d: 'm5 12 7-7 7 7' }), React.createElement('path', { d: 'M12 19V5' })),
            'Plus': React.createElement('svg', { xmlns: '[http://www.w3.org/2000/svg](http://www.w3.org/2000/svg)', width: size, height: size, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', strokeWidth: '2', strokeLinecap: 'round', strokeLinejoin: 'round', className: className }, React.createElement('line', { x1: '12', x2: '12', y1: '5', y2: '19' }), React.createElement('line', { x1: '5', x2: '19', y1: '12', y2: '12' }))
        };
        return icons[name] || React.createElement("span", { className: className }, name);
    };


    const renderUserId = () => {
        if (!isAuthReady) {
            return React.createElement("div", { className: "text-sm text-gray-400" }, "Auth Initializing...");
        }
        if (userId) {
            return (
                React.createElement("div", { className: "text-xs text-gray-500 truncate mt-2", title: userId },
                    "User ID: ", React.createElement("span", { className: "font-mono" }, userId)
                )
            );
        }
        return React.createElement("div", { className: "text-sm text-red-400" }, "User ID not available.");
    };

    return (
        React.createElement("div", { className: "flex h-screen bg-[#202123] text-gray-100 font-inter" },
            React.createElement("div", { className: "w-64 bg-[#202123] flex flex-col justify-between py-2 px-3 border-r border-[#343541]" },
                React.createElement("div", null,
                    React.createElement("div", { className: "flex items-center justify-between p-2 mb-2" },
                        React.createElement("span", { className: "text-white text-lg font-semibold" }, "Perception"),
                        React.createElement(LucideIcon, { name: "Ellipsis", className: "text-gray-400 hover:text-white cursor-pointer", size: 20 })
                    ),
                    React.createElement("button", {
                        onClick: createNewChatSession,
                        className: "flex items-center gap-2 w-full p-2 text-sm text-gray-300 rounded-md hover:bg-gray-700 hover:text-white transition-colors duration-200",
                        disabled: loading || !isAuthReady
                    },
                        React.createElement(LucideIcon, { name: "SquarePen", size: 18 }), " New chat"
                    ),
                    React.createElement("div", { className: "mt-4 overflow-y-auto max-h-[calc(100vh-200px)] custom-scrollbar pr-1" },
                        chatSessions.length === 0 && !isAuthReady ? (
                            React.createElement("p", { className: "text-gray-500 text-sm text-center" }, "Loading sessions...")
                        ) : chatSessions.length === 0 ? (
                            React.createElement("p", { className: "text-gray-500 text-sm text-center" }, "No chat sessions yet. Start a new one!")
                        ) : (
                            React.createElement(React.Fragment, null,
                                React.createElement("p", { className: "text-xs text-gray-500 uppercase px-2 py-1" }, "Recent Chats"),
                                chatSessions.map(session => (
                                    React.createElement("button", {
                                        key: session.id,
                                        onClick: () => setCurrentSessionId(session.id),
                                        className: `flex items-center gap-2 w-full p-2 text-sm rounded-md transition-colors duration-200 ${
                                            currentSessionId === session.id
                                                ? 'bg-gray-700 text-white'
                                                : 'bg-gray-700 hover:bg-gray-600 text-gray-300'
                                            }`
                                    },
                                        React.createElement(LucideIcon, { name: "MessageSquarePlus", size: 16 }),
                                        React.createElement("span", { className: "truncate" }, session.title || `Chat ${session.id.substring(0, 5)}`)
                                    )
                                ))
                            )
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
            React.createElement("div", { className: "flex-1 flex flex-col bg-[#343541]" },
                React.createElement("header", { className: "bg-[#343541] p-3 border-b border-gray-700 flex items-center justify-between text-white shadow-md" },
                    React.createElement("div", { className: "flex items-center gap-2" },
                        React.createElement("span", { className: "font-semibold text-lg" }, "Perception")
                    ),
                    React.createElement("div", { className: "flex items-center gap-2" },
                        React.createElement("div", { className: "w-8 h-8 rounded-full bg-blue-500 flex items-center justify-center text-sm font-bold" }, "S"),
                        React.createElement(LucideIcon, { name: "Ellipsis", className: "text-gray-400 hover:text-white cursor-pointer", size: 20 })
                    )
                ),
                React.createElement("div", { className: "flex-1 flex flex-col items-center justify-between p-6 overflow-y-auto custom-scrollbar" },
                    messages.length === 0 && !loading && (
                        React.createElement("div", { className: "flex flex-col items-center justify-center h-full text-center text-gray-400" },
                            React.createElement("h2", { className: "text-3xl font-bold mb-8 text-white" }, "What are you working on?"),
                            React.createElement("div", { className: "grid grid-cols-2 gap-4 max-w-lg w-full" },
                                React.createElement("div", { className: "p-4 bg-[#444654] rounded-lg shadow-md flex flex-col items-center justify-center text-sm cursor-pointer hover:bg-[#505260] transition-colors" },
                                    React.createElement(LucideIcon, { name: "Image", size: 24, className: "mb-2" }), " Create an image"
                                ),
                                React.createElement("div", { className: "p-4 bg-[#444654] rounded-lg shadow-md flex flex-col items-center justify-center text-sm cursor-pointer hover:bg-[#505260] transition-colors" },
                                    React.createElement(LucideIcon, { name: "Sparkles", size: 24, className: "mb-2" }), " Get advice"
                                ),
                                React.createElement("div", { className: "p-4 bg-[#444654] rounded-lg shadow-md flex flex-col items-center justify-center text-sm cursor-pointer hover:bg-[#505260] transition-colors" },
                                    React.createElement(LucideIcon, { name: "Code", size: 24, className: "mb-2" }), " Write code"
                                ),
                                React.createElement("div", { className: "p-4 bg-[#444654] rounded-lg shadow-md flex flex-col items-center justify-center text-sm cursor-pointer hover:bg-[#505260] transition-colors" },
                                    React.createElement(LucideIcon, { name: "Search", size: 24, className: "mb-2" }), " Summarize text"
                                )
                            )
                        )
                    ),
                    React.createElement("div", { className: "w-full max-w-3xl mx-auto flex-grow flex-col justify-end" },
                        messages.map((msg, index) => (
                            React.createElement("div", {
                                key: index,
                                className: `flex items-start gap-3 p-4 rounded-lg mb-4 ${
                                    msg.sender === 'user' ? 'bg-[#343541] justify-end' : 'bg-[#444654]'
                                    }`
                            },
                                React.createElement("div", { className: `flex-shrink-0 w-8 h-8 rounded-full flex items-center justify-center font-bold text-sm ${msg.sender === 'user' ? 'bg-blue-500' : 'bg-[#10a37f]'}` },
                                    msg.sender === 'user' ? 'U' : 'AI'
                                ),
                                React.createElement("div", { className: `flex-1 ${msg.sender === 'user' ? 'text-right' : 'text-left'} break-words` },
                                    renderMessageContent(msg.text),
                                    React.createElement("span", { className: "block text-xs opacity-75 mt-1 text-gray-400" },
                                        new Date(msg.timestamp).toLocaleTimeString()
                                    )
                                )
                            )
                        )),
                        loading && (
                            React.createElement("div", { className: "flex items-start gap-3 p-4 rounded-lg bg-[#444654] mb-4" },
                                React.createElement("div", { className: "flex-shrink-0 w-8 h-8 rounded-full bg-[#10a37f] flex items-center justify-center font-bold text-sm" }, "AI"),
                                React.createElement("div", { className: "flex-1" },
                                    React.createElement("p", { className: "font-semibold text-sm mb-1" }, "AI Assistant"),
                                    React.createElement("div", { className: "flex items-center" },
                                        React.createElement("div", { className: "w-2 h-2 bg-gray-400 rounded-full animate-bounce mr-1" }),
                                        React.createElement("div", { className: "w-2 h-2 bg-gray-400 rounded-full animate-bounce delay-150 mr-1" }),
                                        React.createElement("div", { className: "w-2 h-2 bg-gray-400 rounded-full animate-bounce delay-300" })
                                    )
                                )
                            )
                        ),
                        React.createElement("div", { ref: messagesEndRef })
                    )
                ),
                React.createElement("form", { onSubmit: handleSendMessage, className: "p-4 bg-[#343541] border-t border-gray-700 shadow-inner" },
                    React.createElement("div", { className: "flex max-w-3xl mx-auto" },
                        React.createElement("input", {
                            type: "text",
                            value: input,
                            onChange: (e) => setInput(e.target.value),
                            placeholder: "Ask anything...",
                            className: "flex-1 p-3 rounded-l-lg bg-gray-700 border border-gray-600 focus:outline-none focus:border-blue-500 text-white placeholder-gray-400",
                            disabled: loading || !currentSessionId
                        }),
                        React.createElement("button", {
                            type: "submit",
                            className: "p-2 rounded-lg text-gray-400 hover:text-white hover:bg-gray-600 transition-colors duration-200",
                            disabled: loading || !currentSessionId || !input.trim()
                        },
                            React.createElement(LucideIcon, { name: "ArrowUp", size: 24 })
                        )
                    ),
                    React.createElement("p", { className: "text-center text-xs text-gray-500 mt-2" }, "Please note that while I strive for accuracy, the information I provide is based on the documentation and examples available to me. For critical applications, always verify the code and information with the official Perception.cx documentation.")
                )
            )
        )
    );
};

export default App;
