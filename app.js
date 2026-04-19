function showRegister() {
            const loginForm = document.getElementById('login-form');
            const registerForm = document.getElementById('register-form');
            if (loginForm) loginForm.classList.add('hidden');
            if (registerForm) registerForm.classList.remove('hidden');
            const usernameInput = document.getElementById('register-username');
            if (usernameInput) usernameInput.focus();
            // 重置到步骤1
            const step1 = document.getElementById('register-step-1');
            const step2 = document.getElementById('register-step-2');
            const indicator1 = document.getElementById('step-1-indicator');
            const indicator2 = document.getElementById('step-2-indicator');
            const divider = document.getElementById('step-divider');
            if (step1) step1.classList.remove('hidden');
            if (step2) step2.classList.add('hidden');
            if (indicator1) indicator1.classList.add('active');
            if (indicator2) indicator2.classList.remove('active');
            if (divider) divider.classList.remove('active');
        }
        
        function showLogin() {
            const loginForm = document.getElementById('login-form');
            const registerForm = document.getElementById('register-form');
            if (loginForm) loginForm.classList.remove('hidden');
            if (registerForm) registerForm.classList.add('hidden');
            const usernameInput = document.getElementById('login-username');
            if (usernameInput) usernameInput.focus();
            // 重置头像预览
            const preview = document.getElementById('avatar-preview');
            const input = document.getElementById('avatar-input');
            if (preview) preview.innerHTML = '<span>?</span>';
            if (input) input.value = '';
        }
        
        function goToStep1() {
            const step1 = document.getElementById('register-step-1');
            const step2 = document.getElementById('register-step-2');
            const indicator1 = document.getElementById('step-1-indicator');
            const indicator2 = document.getElementById('step-2-indicator');
            const divider = document.getElementById('step-divider');
            if (step1) step1.classList.remove('hidden');
            if (step2) step2.classList.add('hidden');
            if (indicator1) indicator1.classList.add('active');
            if (indicator2) indicator2.classList.remove('active');
            if (divider) divider.classList.remove('active');
        }
        
        function goToStep2() {
            const username = document.getElementById('register-username')?.value.trim();
            const password = document.getElementById('register-password')?.value;
            const confirmPassword = document.getElementById('register-confirm')?.value;
            
            if (!username) {
                alert('请输入用户名');
                return;
            }
            if (!password) {
                alert('请输入密码');
                return;
            }
            if (password !== confirmPassword) {
                alert('两次输入的密码不一致');
                return;
            }
            
            const step1 = document.getElementById('register-step-1');
            const step2 = document.getElementById('register-step-2');
            const indicator1 = document.getElementById('step-1-indicator');
            const indicator2 = document.getElementById('step-2-indicator');
            const divider = document.getElementById('step-divider');
            if (step1) step1.classList.add('hidden');
            if (step2) step2.classList.remove('hidden');
            if (indicator1) indicator1.classList.add('active');
            if (indicator2) indicator2.classList.add('active');
            if (divider) divider.classList.add('active');
        }

// ========== 数据存储 ==========
        // 基础 key，实际使用时会加上用户标识进行隔离
        const BASE_STORAGE_KEY = 'schedule-v5';
        const WEATHER_KEY = 'schedule-weather-city';
        
        // 获取当前用户隔离的存储key
        function getUserStorageKey(baseKey) {
            const userId = currentUser ? currentUser.username : 'guest';
            return `${baseKey}-${userId}`;
        }
        
        // 获取任务存储key
        function getTasksKey() {
            return getUserStorageKey(BASE_STORAGE_KEY);
        }
        
        // 获取日记存储key
        function getDiaryStorageKey() {
            return getUserStorageKey('schedule-diaries');
        }
        
        // 获取情绪存储key
        function getMoodKey() {
            return getUserStorageKey('schedule-moods');
        }
        
        // 获取语音奖励存储key
        function getAudioRewardKey() {
            return getUserStorageKey('schedule-audio-rewards');
        }
        
        // 获取设置存储key
        function getSettingsKey() {
            return getUserStorageKey('schedule-settings');
        }
        
        let tasks = [];
        let currentDate = new Date();
        let currentView = 'day';
        let currentMonth = new Date();
        let sideCalMonth = new Date();
        let currentCity = null;
        
        // 批量删除模式状态
        let isBatchDeleteMode = false;
        let selectedTaskIds = new Set();
        
        // 任务模板 - 用户隔离
        function getTemplatesKey() {
            return getUserStorageKey('schedule-templates');
        }
        
        // 预设模板
        const DEFAULT_TEMPLATES = {
            morning: {
                id: 'morning',
                name: '早晨 routine',
                icon: '🌅',
                isDefault: true,
                tasks: [
                    { name: '起床', icon: '🛏️', time: '07:00' },
                    { name: '刷牙洗脸', icon: '🪥', time: '07:15' },
                    { name: '吃早餐', icon: '🍽️', time: '07:30' },
                    { name: '换衣服', icon: '👕', time: '07:50' },
                    { name: '准备出门', icon: '🎒', time: '08:00' }
                ]
            },
            evening: {
                id: 'evening',
                name: '睡前 routine',
                icon: '🌙',
                isDefault: true,
                tasks: [
                    { name: '吃晚餐', icon: '🍽️', time: '18:00' },
                    { name: '洗澡', icon: '🛁', time: '19:30' },
                    { name: '刷牙', icon: '🪥', time: '20:00' },
                    { name: '读故事书', icon: '📚', time: '20:15' },
                    { name: '睡觉', icon: '🛏️', time: '20:30' }
                ]
            },
            school: {
                id: 'school',
                name: '上学日',
                icon: '🎒',
                isDefault: true,
                tasks: [
                    { name: '到校', icon: '🏫', time: '08:30' },
                    { name: '课间休息', icon: '🏃', time: '10:00' },
                    { name: '午餐时间', icon: '🍱', time: '12:00' },
                    { name: '放学', icon: '🏠', time: '16:00' },
                    { name: '做作业', icon: '✏️', time: '16:30' }
                ]
            }
        };
        
        // 常用任务库（一键添加）
        const COMMON_TASKS = {
            morning: [
                { id: 'wake-up', name: '起床', icon: '🛏️', defaultTime: '07:00' },
                { id: 'brush-teeth', name: '刷牙', icon: '🪥', defaultTime: '07:15' },
                { id: 'wash-face', name: '洗脸', icon: '🧼', defaultTime: '07:20' },
                { id: 'breakfast', name: '吃早餐', icon: '🍽️', defaultTime: '07:30' },
                { id: 'get-dressed', name: '穿衣服', icon: '👕', defaultTime: '07:50' },
                { id: 'pack-bag', name: '收拾书包', icon: '🎒', defaultTime: '07:55' },
                { id: 'go-school', name: '出门上学', icon: '🚶', defaultTime: '08:00' }
            ],
            noon: [
                { id: 'lunch', name: '吃午餐', icon: '🍱', defaultTime: '12:00' },
                { id: 'nap', name: '午休', icon: '😴', defaultTime: '12:45' }
            ],
            afternoon: [
                { id: 'snack', name: '吃点心', icon: '🍪', defaultTime: '15:30' },
                { id: 'homework', name: '做作业', icon: '✏️', defaultTime: '16:30' },
                { id: 'play', name: '玩游戏', icon: '🎮', defaultTime: '17:30' },
                { id: 'exercise', name: '运动', icon: '🏃', defaultTime: '17:00' }
            ],
            evening: [
                { id: 'dinner', name: '吃晚餐', icon: '🍽️', defaultTime: '18:00' },
                { id: 'bath', name: '洗澡', icon: '🛁', defaultTime: '19:30' },
                { id: 'brush-night', name: '睡前刷牙', icon: '🪥', defaultTime: '20:00' },
                { id: 'read', name: '读故事书', icon: '📚', defaultTime: '20:15' },
                { id: 'sleep', name: '睡觉', icon: '🌙', defaultTime: '20:30' }
            ]
        };
        
        let currentCommonTaskCategory = 'morning';
        
        // 渲染常用任务网格
        function renderCommonTasks(category) {
            const grid = document.getElementById('common-tasks-grid');
            const tasks = COMMON_TASKS[category] || [];
            
            grid.innerHTML = tasks.map(task => `
                <button class="common-task-btn" onclick="addCommonTask('${category}', '${task.id}')" title="${task.name}">
                    <span class="icon">${task.icon}</span>
                    <span class="name">${task.name}</span>
                </button>
            `).join('');
        }
        
        // 切换常用任务分类
        function switchCommonTaskCategory(category) {
            currentCommonTaskCategory = category;
            
            // 更新标签样式
            document.querySelectorAll('.category-tab').forEach(tab => {
                tab.classList.toggle('active', tab.dataset.category === category);
            });
            
            // 渲染对应分类的任务
            renderCommonTasks(category);
        }
        
        // 添加常用任务
        function addCommonTask(category, taskId) {
            const task = COMMON_TASKS[category].find(t => t.id === taskId);
            if (!task) return;
            
            // 获取当前选择的日期
            const dateInput = document.getElementById('add-date');
            const selectedDate = dateInput.value || new Date().toISOString().split('T')[0];
            
            // 创建任务对象
            const newTask = {
                id: Date.now().toString(),
                name: task.name,
                time: task.defaultTime,
                icon: task.icon,
                completed: false,
                date: selectedDate,
                createdAt: new Date().toISOString()
            };
            
            // 添加到任务列表
            tasks.push(newTask);
            saveTasks();
            renderAll();
            
            // 显示成功提示
            showToast(`已添加: ${task.icon} ${task.name}`);
            
            // 关闭添加面板
            closeAddPanel();
        }
        
        // 预设城市列表
        const CITIES = [
            { name: '北京', lat: 39.9042, lon: 116.4074 },
            { name: '上海', lat: 31.2304, lon: 121.4737 },
            { name: '广州', lat: 23.1291, lon: 113.2644 },
            { name: '深圳', lat: 22.5431, lon: 114.0579 },
            { name: '杭州', lat: 30.2741, lon: 120.1551 },
            { name: '成都', lat: 30.5728, lon: 104.0668 },
            { name: '武汉', lat: 30.5928, lon: 114.3055 },
            { name: '西安', lat: 34.3416, lon: 108.9398 },
            { name: '南京', lat: 32.0603, lon: 118.7969 },
            { name: '重庆', lat: 29.5630, lon: 106.5516 },
            { name: '天津', lat: 39.1252, lon: 117.1904 },
            { name: '苏州', lat: 31.2989, lon: 120.5853 },
            { name: '香港', lat: 22.3193, lon: 114.1694 },
            { name: '台北', lat: 25.0330, lon: 121.5654 },
            { name: '东京', lat: 35.6762, lon: 139.6503 },
            { name: '纽约', lat: 40.7128, lon: -74.0060 },
            { name: '伦敦', lat: 51.5074, lon: -0.1278 },
            { name: '巴黎', lat: 48.8566, lon: 2.3522 },
            { name: '悉尼', lat: -33.8688, lon: 151.2093 },
            { name: '新加坡', lat: 1.3521, lon: 103.8198 }
        ];
        
        // 天气图标映射
        const WEATHER_ICONS = {
            0: '☀️', // 晴
            1: '🌤️', // 多云
            2: '⛅', // 阴天
            3: '☁️', // 阴
            45: '🌫️', // 雾
            48: '🌫️', // 雾凇
            51: '🌧️', // 毛毛雨
            53: '🌧️', // 中雨
            55: '🌧️', // 大雨
            61: '🌧️', // 小雨
            63: '🌧️', // 中雨
            65: '🌧️', // 大雨
            71: '🌨️', // 小雪
            73: '🌨️', // 中雪
            75: '🌨️', // 大雪
            95: '⛈️', // 雷雨
            96: '⛈️', // 雷伴有冰雹
            99: '⛈️'  // 雷伴有重冰雹
        };
        
        const WEATHER_DESC = {
            0: '晴天',
            1: '多云',
            2: '阴天',
            3: '阴天',
            45: '雾',
            48: '雾凇',
            51: '毛毛雨',
            53: '中雨',
            55: '大雨',
            61: '小雨',
            63: '中雨',
            65: '大雨',
            71: '小雪',
            73: '中雪',
            75: '大雪',
            95: '雷雨',
            96: '雷阵雨',
            99: '强雷雨'
        };
        
        // ========== 初始化 ==========
        document.addEventListener('DOMContentLoaded', () => {
            tasks = getTasks();
            
            // 加载保存的城市
            const savedCity = localStorage.getItem(WEATHER_KEY);
            if (savedCity) {
                currentCity = JSON.parse(savedCity);
                getWeather(currentCity.lat, currentCity.lon, currentCity.name);
            } else if (appSettings.autoLocate) {
                // 尝试定位
                locateAndGetWeather();
            }
            
            renderAll();
            setupDefaultTime();
            
            // 初始化快捷日期折叠状态
            initQuickDatesState();
            
            // 初始化日历折叠状态
            initSidebarCalendarState();
            
            // 初始化设置
            loadSettings();
            
            // 初始化情绪数据
            loadMoodData();
            
            // 初始化认证状态
            initAuth();
            
            // 初始化云同步状态
            updateCloudSyncUI();
            
            // 初始化模板列表
            renderTemplateManageList();
            
            // 初始化常用任务
            renderCommonTasks('morning');
            
            // 预加载语音合成列表（用于语音播报功能）
            if (window.speechSynthesis) {
                // 某些浏览器需要用户交互后才能加载语音列表
                window.speechSynthesis.getVoices();
            }
        });
        
        // ========== 设置功能 ==========
        // 注意：SETTINGS_KEY 现在通过 getSettingsKey() 函数动态获取，实现用户隔离
        let appSettings = {
            mode: 'parent', // 'parent' | 'child'
            theme: 'light', // 'light' | 'dark' | 'blue' | 'green' | 'warm' | 'high-contrast' | 'dyslexia'
            fontSize: 'normal', // 'small' | 'normal' | 'large'
            timeFormat: '24h', // '24h' | '12h'
            weekStart: 'monday', // 'sunday' | 'monday'
            defaultView: 'day', // 'day' | 'month' | 'list'
            autoLocate: false,
            showHelpOnStart: true,
            teamMode: false, // 团队模式开关
            teamMembers: [], // 团队成员列表 {id, name, color}
            currentMemberId: null, // 当前登录的成员ID
            childSettings: {
                showWeather: true,
                showImages: true,
                colorCoding: true,
                largeCards: true,
                voicePrompts: true
            },
            // 完成任务音效设置
            completeSound: true
        };
        
        let settingsTempAvatar = null;
        
        function loadSettings() {
            const saved = localStorage.getItem(getSettingsKey());
            if (saved) {
                appSettings = { ...appSettings, ...JSON.parse(saved) };
            }
            applySettings();
        }
        
        function saveSettings() {
            // 收集儿童模式设置
            if (appSettings.mode === 'child') {
                appSettings.childSettings = {
                    showWeather: document.getElementById('child-show-weather').checked,
                    showImages: document.getElementById('child-show-images').checked,
                    colorCoding: document.getElementById('child-color-coding').checked,
                    largeCards: document.getElementById('child-large-cards').checked,
                    voicePrompts: document.getElementById('child-voice-prompts').checked
                };
            }
            
            // 收集显示设置
            const timeFormat = document.querySelector('input[name="settings-time-format"]:checked');
            if (timeFormat) appSettings.timeFormat = timeFormat.value;
            
            const weekStart = document.querySelector('input[name="settings-week-start"]:checked');
            if (weekStart) appSettings.weekStart = weekStart.value;
            
            const defaultView = document.getElementById('settings-default-view');
            if (defaultView) appSettings.defaultView = defaultView.value;
            
            // 收集天气设置
            appSettings.autoLocate = document.getElementById('settings-auto-locate').checked;
            
            // 收集帮助设置
            appSettings.showHelpOnStart = document.getElementById('settings-show-help').checked;
            
            // 收集音效设置
            appSettings.completeSound = document.getElementById('settings-complete-sound').checked;
            
            // 保存设置
            localStorage.setItem(getSettingsKey(), JSON.stringify(appSettings));
            
            // 更新用户信息
            updateUserInfoFromSettings();
            
            applySettings();
            closeSettingsModal();
            showToast('设置已保存');
        }
        
        function updateUserInfoFromSettings() {
            if (!currentUser) return;
            
            const newUsername = document.getElementById('settings-username').value.trim();
            const newPassword = document.getElementById('settings-new-password').value;
            
            // 更新用户名
            if (newUsername && newUsername !== currentUser.username) {
                const users = JSON.parse(localStorage.getItem('schedule-users') || '[]');
                const existingUser = users.find(u => u.username === newUsername && u.username !== currentUser.username);
                if (existingUser) {
                    showToast('用户名已存在');
                    return;
                }
                
                // 更新当前用户的用户名
                const userIndex = users.findIndex(u => u.username === currentUser.username);
                if (userIndex !== -1) {
                    users[userIndex].username = newUsername;
                    currentUser.username = newUsername;
                }
                localStorage.setItem('schedule-users', JSON.stringify(users));
            }
            
            // 更新头像
            if (settingsTempAvatar) {
                const users = JSON.parse(localStorage.getItem('schedule-users') || '[]');
                const userIndex = users.findIndex(u => u.username === currentUser.username);
                if (userIndex !== -1) {
                    users[userIndex].avatar = settingsTempAvatar;
                    currentUser.avatar = settingsTempAvatar;
                }
                localStorage.setItem('schedule-users', JSON.stringify(users));
                settingsTempAvatar = null;
            }
            
            // 更新密码
            if (newPassword) {
                if (newPassword.length < 6) {
                    showToast('密码长度至少6位');
                    return;
                }
                const users = JSON.parse(localStorage.getItem('schedule-users') || '[]');
                const userIndex = users.findIndex(u => u.username === currentUser.username);
                if (userIndex !== -1) {
                    users[userIndex].password = newPassword;
                    currentUser.password = newPassword;
                }
                localStorage.setItem('schedule-users', JSON.stringify(users));
                document.getElementById('settings-new-password').value = '';
            }
            
            // 更新显示
            localStorage.setItem(AUTH_KEY, JSON.stringify({ isLoggedIn: true, user: currentUser }));
            updateUserInfo();
        }
        
        function applySettings() {
            // 应用模式
            document.body.classList.toggle('child-mode', appSettings.mode === 'child');
            
            // 更新侧边栏徽章
            const badge = document.getElementById('sidebar-mode-badge');
            if (badge) {
                badge.textContent = appSettings.mode === 'parent' ? '家长' : '小朋友';
                badge.classList.toggle('child', appSettings.mode === 'child');
            }
            
            // 应用主题
            document.documentElement.setAttribute('data-theme', appSettings.theme);
            
            // 应用字体大小
            document.body.classList.remove('font-small', 'font-normal', 'font-large');
            document.body.classList.add(`font-${appSettings.fontSize}`);
            
            // 应用默认视图
            if (appSettings.defaultView && appSettings.defaultView !== currentView) {
                switchView(appSettings.defaultView);
            }
            
            // 重新渲染
            renderAll();
        }
        
        function openSettingsModal() {
            // 重置临时头像
            settingsTempAvatar = null;
            
            // 更新UI状态
            updateSettingsUI();
            document.getElementById('settings-modal').classList.add('show');
        }
        
        function closeSettingsModal(e) {
            if (!e || e.target.id === 'settings-modal') {
                document.getElementById('settings-modal').classList.remove('show');
            }
        }

        // ========== 语音助手功能 ==========
        // 注意：mediaRecorder 在任务奖励部分已声明
        let isRecordingVoice = false;
        let voiceRecordingTimer = null;
        let voiceRecordingSeconds = 0;
        let recognition = null;
        
        function openVoiceAssistant() {
            document.getElementById('voice-modal').classList.remove('hidden');
            resetVoiceRecording();
            if (!('webkitSpeechRecognition' in window) && !('SpeechRecognition' in window)) {
                document.getElementById('voice-status').textContent = '您的浏览器不支持语音识别，请使用 Chrome 浏览器';
                document.getElementById('voice-record-btn').disabled = true;
                document.getElementById('voice-record-btn').style.opacity = '0.5';
            }
        }
        
        function closeVoiceModal(e) {
            if (!e || e.target.id === 'voice-modal') {
                if (isRecordingVoice) stopVoiceRecording();
                document.getElementById('voice-modal').classList.add('hidden');
            }
        }
        
        function toggleVoiceRecording() {
            if (isRecordingVoice) stopVoiceRecording();
            else startVoiceRecording();
        }
        
        function startVoiceRecording() {
            const SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition;
            if (!SpeechRecognition) {
                showToast('您的浏览器不支持语音识别功能');
                return;
            }
            
            recognition = new SpeechRecognition();
            recognition.lang = 'zh-CN';
            recognition.continuous = true;
            recognition.interimResults = true;
            
            isRecordingVoice = true;
            voiceRecordingSeconds = 0;
            
            document.getElementById('voice-status').textContent = '正在录音，请说话...';
            document.getElementById('voice-record-btn').style.background = '#EF4444';
            document.getElementById('voice-recording-indicator').style.display = 'block';
            document.getElementById('voice-result').style.display = 'none';
            
            updateRecordingTimer();
            voiceRecordingTimer = setInterval(updateVoiceRecordingTimer, 1000);
            
            recognition.onresult = function(event) {
                let finalTranscript = '';
                let interimTranscript = '';
                for (let i = event.resultIndex; i < event.results.length; i++) {
                    const transcript = event.results[i][0].transcript;
                    if (event.results[i].isFinal) finalTranscript += transcript;
                    else interimTranscript += transcript;
                }
                const text = finalTranscript || interimTranscript;
                document.getElementById('voice-text').value = text;
                if (text) parseVoiceCommand(text);
            };
            
            recognition.onerror = function(event) {
                if (event.error === 'not-allowed') {
                    showToast('请允许使用麦克风权限');
                    stopVoiceRecording();
                }
            };
            
            recognition.onend = function() {
                if (isRecordingVoice) {
                    try { recognition.start(); } catch(e) {}
                }
            };
            
            try {
                recognition.start();
            } catch(e) {
                showToast('无法启动录音，请检查麦克风权限');
                isRecordingVoice = false;
                return;
            }
            
            setTimeout(() => {
                if (isRecordingVoice) {
                    showToast('录音已达到最大时长');
                    stopVoiceRecording();
                }
            }, 60000);
        }
        
        function stopVoiceRecording() {
            isRecording = false;
            if (recognition) {
                try { recognition.stop(); } catch(e) {}
                recognition = null;
            }
            if (recordingTimer) {
                clearInterval(recordingTimer);
                recordingTimer = null;
            }
            document.getElementById('voice-status').textContent = '录音完成';
            document.getElementById('voice-record-btn').style.background = 'var(--accent)';
            document.getElementById('voice-recording-indicator').style.display = 'none';
            document.getElementById('voice-result').style.display = 'block';
            const text = document.getElementById('voice-text').value;
            if (text) parseVoiceCommand(text);
        }
        
        function updateVoiceRecordingTimer() {
            voiceRecordingSeconds++;
            const minutes = Math.floor(voiceRecordingSeconds / 60).toString().padStart(2, '0');
            const seconds = (voiceRecordingSeconds % 60).toString().padStart(2, '0');
            document.getElementById('voice-timer').textContent = minutes + ':' + seconds;
        }
        
        function resetVoiceRecording() {
            isRecordingVoice = false;
            voiceRecordingSeconds = 0;
            if (recognition) {
                try { recognition.stop(); } catch(e) {}
                recognition = null;
            }
            if (recordingTimer) {
                clearInterval(recordingTimer);
                recordingTimer = null;
            }
            document.getElementById('voice-status').textContent = '点击麦克风开始录音';
            document.getElementById('voice-record-btn').style.background = 'var(--accent)';
            document.getElementById('voice-recording-indicator').style.display = 'none';
            document.getElementById('voice-result').style.display = 'none';
            document.getElementById('voice-text').value = '';
            document.getElementById('voice-task-name').textContent = '等待识别...';
            document.getElementById('voice-task-time').textContent = '';
        }
        
        function parseVoiceCommand(text) {
            if (!text) return;
            let timeStr = '';
            let taskName = text;
            let hour = null;
            let minute = 0;
            
            const patterns = [
                { regex: /(早上|上午|中午|下午|晚上)?\\s*(\\d{1,2})\\s*点\\s*(\\d{0,2})\\s*分?/, type: 'chinese' },
                { regex: /(\\d{1,2}):(\\d{2})/, type: 'colon' },
                { regex: /(\\d{1,2})\\s*点半/, type: 'half' }
            ];
            
            for (const p of patterns) {
                const match = text.match(p.regex);
                if (match) {
                    if (p.type === 'chinese') {
                        const period = match[1] || '';
                        hour = parseInt(match[2]);
                        minute = parseInt(match[3]) || 0;
                        if (period === '下午' || period === '晚上') {
                            if (hour !== 12) hour += 12;
                        } else if (period === '早上' || period === '上午') {
                            if (hour === 12) hour = 0;
                        }
                        taskName = text.replace(match[0], '').trim();
                    } else if (p.type === 'colon') {
                        hour = parseInt(match[1]);
                        minute = parseInt(match[2]);
                        taskName = text.replace(match[0], '').trim();
                    } else if (p.type === 'half') {
                        hour = parseInt(match[1]);
                        minute = 30;
                        taskName = text.replace(match[0], '').trim();
                    }
                    break;
                }
            }
            
            if (hour !== null) {
                timeStr = String(hour).padStart(2, '0') + ':' + String(minute).padStart(2, '0');
            }
            
            if (!timeStr) {
                const now = new Date();
                now.setHours(now.getHours() + 1);
                timeStr = String(now.getHours()).padStart(2, '0') + ':00';
            }
            
            if (!taskName || taskName.length < 2) {
                taskName = text;
            }
            
            document.getElementById('voice-task-name').textContent = '任务：' + taskName;
            document.getElementById('voice-task-time').textContent = '时间：' + timeStr;
            document.getElementById('voice-task-name').dataset.taskName = taskName;
            document.getElementById('voice-task-time').dataset.taskTime = timeStr;
        }
        
        function createTaskFromVoice() {
            const taskName = document.getElementById('voice-task-name').dataset.taskName;
            const taskTime = document.getElementById('voice-task-time').dataset.taskTime;
            
            if (!taskName) {
                showToast('请先录制语音');
                return;
            }
            
            const task = {
                id: Date.now().toString(),
                name: taskName,
                time: taskTime || '09:00',
                icon: '',
                endTime: '',
                completed: false,
                date: currentDate.toISOString()
            };
            
            tasks.push(task);
            saveTasks();
            renderAll();
            closeVoiceModal();
            showToast('任务创建成功：' + taskName);
        }
        
        // ========== AI 智能日程助手 ==========
        let aiParsedTasks = [];
        
        function openAIAssistant() {
            document.getElementById('ai-assistant-modal').classList.remove('hidden');
            resetAIAssistant();
            document.getElementById('ai-schedule-input').focus();
        }
        
        function closeAIAssistantModal(e) {
            if (!e || e.target.id === 'ai-assistant-modal') {
                document.getElementById('ai-assistant-modal').classList.add('hidden');
            }
        }
        
        function resetAIAssistant() {
            aiParsedTasks = [];
            document.getElementById('ai-schedule-input').value = '';
            document.getElementById('ai-input-area').style.display = 'block';
            document.getElementById('ai-preview-area').style.display = 'none';
        }
        
        function backToAIInput() {
            document.getElementById('ai-input-area').style.display = 'block';
            document.getElementById('ai-preview-area').style.display = 'none';
        }
        
        function parseAISchedule() {
            const text = document.getElementById('ai-schedule-input').value.trim();
            if (!text) {
                showToast('请输入日程描述');
                return;
            }
            
            aiParsedTasks = parseSmartSchedule(text);
            
            if (aiParsedTasks.length === 0) {
                showToast('未识别到有效任务，请尝试更具体的描述');
                return;
            }
            
            renderAIPreview();
            document.getElementById('ai-input-area').style.display = 'none';
            document.getElementById('ai-preview-area').style.display = 'block';
        }
        
        function renderAIPreview() {
            const container = document.getElementById('ai-task-list');
            const summary = document.getElementById('ai-parse-summary');
            
            const dates = [...new Set(aiParsedTasks.map(t => t.date))].sort();
            summary.textContent = `共 ${aiParsedTasks.length} 个任务，${dates.length} 个日期`;
            
            let html = '';
            dates.forEach(dateStr => {
                const dateTasks = aiParsedTasks.filter(t => t.date === dateStr);
                const dateLabel = getRelativeDateLabel(dateStr);
                html += `<div style="margin-bottom: 16px;"><div style="font-weight: 600; font-size: 14px; color: var(--accent); margin-bottom: 8px; padding: 6px 10px; background: var(--bg-secondary); border-radius: var(--radius);">${dateLabel}</div>`;
                html += dateTasks.map((task, idx) => {
                    const globalIdx = aiParsedTasks.indexOf(task);
                    const timeDisplay = task.endTime ? `${task.time} - ${task.endTime}` : task.time;
                    const tagHtml = task.tag ? `<span style="display: inline-block; padding: 2px 8px; border-radius: 4px; font-size: 12px; margin-left: 8px; background: ${getTagColor(task.tag)}20; color: ${getTagColor(task.tag)};">${task.tag}</span>` : '';
                    return `
                        <div style="display: flex; align-items: center; gap: 12px; padding: 12px; border: 1px solid var(--border); border-radius: var(--radius); margin-bottom: 8px; ${task.timeInferred ? 'border-left: 3px solid var(--warning);' : ''}">
                            <input type="checkbox" id="ai-task-${globalIdx}" checked onchange="aiParsedTasks[${globalIdx}].selected = this.checked" style="width: 18px; height: 18px; flex-shrink: 0;">
                            <div style="flex: 1; min-width: 0;">
                                <div style="font-weight: 500; font-size: 15px; margin-bottom: 2px;">${escapeHtml(task.name)} ${tagHtml}</div>
                                <div style="font-size: 13px; color: var(--text-secondary);">
                                    🕐 ${timeDisplay} ${task.timeInferred ? '<span style="color: var(--warning);">(推断)</span>' : ''}
                                </div>
                            </div>
                        </div>
                    `;
                }).join('');
                html += '</div>';
            });
            
            container.innerHTML = html;
        }
        
        function getTagColor(tag) {
            const colors = {
                '工作': '#3B82F6', '学习': '#8B5CF6', '生活': '#10B981',
                '健康': '#F59E0B', '娱乐': '#EC4899', '重要': '#EF4444',
                '医院': '#EF4444', '感统': '#8B5CF6', '作业': '#3B82F6',
                '运动': '#10B981', '吃饭': '#F59E0B', '睡觉': '#818CF8',
                '默认': '#6B7280'
            };
            return colors[tag] || colors['默认'];
        }
        
        function getRelativeDateLabel(dateStr) {
            const today = new Date().toISOString().split('T')[0];
            const tomorrow = new Date(Date.now() + 86400000).toISOString().split('T')[0];
            const dayAfter = new Date(Date.now() + 172800000).toISOString().split('T')[0];
            
            if (dateStr === today) return '📅 今天 (' + dateStr + ')';
            if (dateStr === tomorrow) return '📅 明天 (' + dateStr + ')';
            if (dateStr === dayAfter) return '📅 后天 (' + dateStr + ')';
            
            const date = new Date(dateStr);
            const weekdays = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];
            return `📅 ${dateStr} ${weekdays[date.getDay()]}`;
        }
        
        async function confirmAIImport() {
            const toImport = aiParsedTasks.filter(t => t.selected !== false);
            if (toImport.length === 0) {
                showToast('未选择任何任务');
                return;
            }
            
            let addedCount = 0;
            toImport.forEach(task => {
                const allTasks = Storage.getAllTasks ? Storage.getAllTasks() : (typeof tasks !== 'undefined' ? tasks : []);
                const taskToSave = {
                    id: 'ai-' + Date.now().toString() + '-' + Math.random().toString(36).substr(2, 5),
                    name: task.name,
                    time: task.time,
                    endTime: task.endTime || '',
                    icon: task.icon || '',
                    completed: false,
                    date: task.date,
                    tag: task.tag || '',
                    repeat: 'none',
                    remind: ''
                };
                
                // 使用全局 Storage 或回退到本地存储
                if (typeof Storage !== 'undefined' && Storage.saveTask) {
                    Storage.saveTask(taskToSave);
                } else {
                    // 回退：直接操作 localStorage
                    const key = 'schedule-unified-v2';
                    const data = localStorage.getItem(key);
                    let all = data ? JSON.parse(data) : [];
                    all.push(taskToSave);
                    localStorage.setItem(key, JSON.stringify(all));
                }
                addedCount++;
            });
            
            // 刷新当前视图
            if (typeof updateAllViews === 'function') {
                tasks = Storage.getTasks ? Storage.getTasks(currentDate) : tasks;
                await updateAllViews();
            } else if (typeof renderAll === 'function') {
                renderAll();
            }
            
            closeAIAssistantModal();
            showToast(`成功添加 ${addedCount} 个任务`);
        }
        
        function updateSettingsUI() {
            // 更新用户信息
            if (currentUser) {
                document.getElementById('settings-username').value = currentUser.username || '';
                const avatarEl = document.getElementById('settings-avatar');
                if (currentUser.avatar) {
                    avatarEl.innerHTML = `<img src="${currentUser.avatar}" alt="头像">`;
                } else {
                    avatarEl.innerHTML = `<span>${(currentUser.username || '?').charAt(0).toUpperCase()}</span>`;
                }
            }
            
            // 更新模式选择
            document.getElementById('mode-parent').classList.toggle('active', appSettings.mode === 'parent');
            document.getElementById('mode-child').classList.toggle('active', appSettings.mode === 'child');
            
            // 显示/隐藏儿童设置
            document.getElementById('child-settings').classList.toggle('show', appSettings.mode === 'child');
            
            // 更新儿童设置值
            if (appSettings.childSettings) {
                document.getElementById('child-show-weather').checked = appSettings.childSettings.showWeather;
                document.getElementById('child-show-images').checked = appSettings.childSettings.showImages;
                document.getElementById('child-color-coding').checked = appSettings.childSettings.colorCoding;
                document.getElementById('child-large-cards').checked = appSettings.childSettings.largeCards;
                document.getElementById('child-voice-prompts').checked = appSettings.childSettings.voicePrompts;
            }
            
            // 更新主题选择
            document.querySelectorAll('.theme-option').forEach(option => option.classList.remove('active'));
            const themeOption = document.querySelector(`.theme-option[data-theme="${appSettings.theme}"]`);
            if (themeOption) themeOption.classList.add('active');
            
            // 更新字体大小
            document.querySelectorAll('.font-size-selector button').forEach(btn => btn.classList.remove('active'));
            document.getElementById(`font-${appSettings.fontSize}`).classList.add('active');
            
            // 更新时间格式
            const timeFormatRadio = document.querySelector(`input[name="settings-time-format"][value="${appSettings.timeFormat}"]`);
            if (timeFormatRadio) timeFormatRadio.checked = true;
            
            // 更新周起始日
            const weekStartRadio = document.querySelector(`input[name="settings-week-start"][value="${appSettings.weekStart}"]`);
            if (weekStartRadio) weekStartRadio.checked = true;
            
            // 更新默认视图
            document.getElementById('settings-default-view').value = appSettings.defaultView || 'day';
            
            // 更新天气设置
            document.getElementById('settings-city-name').textContent = currentCity ? currentCity.name : '未设置';
            document.getElementById('settings-auto-locate').checked = appSettings.autoLocate || false;
            
            // 更新帮助设置
            document.getElementById('settings-show-help').checked = appSettings.showHelpOnStart !== false;
            
            // 更新音效设置
            document.getElementById('settings-complete-sound').checked = appSettings.completeSound !== false;
            
            // 更新团队设置
            document.getElementById('team-mode-enabled').checked = appSettings.teamMode || false;
            document.getElementById('team-members-section').style.display = appSettings.teamMode ? 'block' : 'none';
            updateTeamMembersUI();
        }
        
        function switchAppMode(mode) {
            appSettings.mode = mode;
            updateSettingsUI();
        }
        
        function setTheme(theme) {
            appSettings.theme = theme;
            // 立即应用主题预览
            document.documentElement.setAttribute('data-theme', theme);
            updateSettingsUI();
        }
        
        function setFontSize(size) {
            appSettings.fontSize = size;
            updateSettingsUI();
        }
        
        // 切换侧边栏
        function toggleSidebar() {
            const sidebar = document.querySelector('.sidebar');
            sidebar.classList.toggle('open');
        }
        
        // ========== 数据导出功能 ==========
        
        // 生成PDF报告
        function exportPDFReport() {
            const reportWindow = window.open('', '_blank');
            const reportHTML = generatePDFReportHTML();
            reportWindow.document.write(reportHTML);
            reportWindow.document.close();
            reportWindow.print();
            showToast('正在生成PDF报告...');
        }
        
        function generatePDFReportHTML() {
            const now = new Date();
            const userName = currentUser ? currentUser.username : '用户';
            
            // 统计数据
            const totalTasks = tasks.length;
            const completedTasks = tasks.filter(t => t.completed).length;
            const completionRate = totalTasks > 0 ? Math.round(completedTasks / totalTasks * 100) : 0;
            
            // 近30天的情绪统计
            const moodCounts = { 1: 0, 2: 0, 3: 0, 4: 0, 5: 0 };
            let moodTotal = 0;
            for (let i = 0; i < 30; i++) {
                const date = new Date();
                date.setDate(date.getDate() - i);
                const mood = moodData[date.toDateString()];
                if (mood) {
                    moodCounts[mood.level]++;
                    moodTotal++;
                }
            }
            
            const moodLabels = { 5: '非常开心', 4: '开心', 3: '平静', 2: '不开心', 1: '很难受' };
            const moodEmojis = { 5: '😊', 4: '🙂', 3: '😐', 2: '😔', 1: '😢' };
            
            // 生成情绪统计HTML
            let moodStatsHTML = '';
            for (let level = 5; level >= 1; level--) {
                const count = moodCounts[level];
                const percentage = moodTotal > 0 ? Math.round(count / moodTotal * 100) : 0;
                moodStatsHTML += `
                    <tr>
                        <td>${moodEmojis[level]} ${moodLabels[level]}</td>
                        <td>${count} 天</td>
                        <td>${percentage}%</td>
                        <td>
                            <div style="background: #eee; height: 20px; border-radius: 10px; overflow: hidden;">
                                <div style="background: #333; height: 100%; width: ${percentage}%; border-radius: 10px;"></div>
                            </div>
                        </td>
                    </tr>
                `;
            }
            
            return `
                <!DOCTYPE html>
                <html>
                <head>
                    <meta charset="UTF-8">
                    <title>日程管理报告 - ${userName}</title>
                    <style>
                        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; margin: 40px; color: #333; }
                        .header { text-align: center; margin-bottom: 40px; padding-bottom: 20px; border-bottom: 3px solid #333; }
                        .header h1 { font-size: 28px; margin-bottom: 10px; }
                        .header p { color: #666; }
                        .section { margin-bottom: 30px; }
                        .section h2 { font-size: 18px; border-left: 4px solid #333; padding-left: 12px; margin-bottom: 15px; }
                        .stats-grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 20px; margin-bottom: 30px; }
                        .stat-card { background: #f5f5f5; padding: 20px; border-radius: 8px; text-align: center; }
                        .stat-value { font-size: 32px; font-weight: bold; margin-bottom: 5px; }
                        .stat-label { font-size: 14px; color: #666; }
                        table { width: 100%; border-collapse: collapse; }
                        th, td { padding: 12px; text-align: left; border-bottom: 1px solid #ddd; }
                        th { background: #f5f5f5; font-weight: 600; }
                        .progress-bar { background: #eee; height: 20px; border-radius: 10px; overflow: hidden; }
                        .progress-fill { background: #333; height: 100%; border-radius: 10px; }
                        .footer { margin-top: 40px; padding-top: 20px; border-top: 1px solid #ddd; font-size: 12px; color: #999; text-align: center; }
                        @media print { body { margin: 20px; } }
                    </style>
                </head>
                <body>
                    <div class="header">
                        <h1>📋 日程管理报告</h1>
                        <p>用户：${userName} | 生成日期：${now.getFullYear()}年${now.getMonth()+1}月${now.getDate()}日</p>
                    </div>
                    
                    <div class="stats-grid">
                        <div class="stat-card">
                            <div class="stat-value">${totalTasks}</div>
                            <div class="stat-label">总任务数</div>
                        </div>
                        <div class="stat-card">
                            <div class="stat-value">${completedTasks}</div>
                            <div class="stat-label">已完成</div>
                        </div>
                        <div class="stat-card">
                            <div class="stat-value">${completionRate}%</div>
                            <div class="stat-label">完成率</div>
                        </div>
                    </div>
                    
                    <div class="section">
                        <h2>📊 近30天情绪统计</h2>
                        <table>
                            <tr>
                                <th>心情</th>
                                <th>天数</th>
                                <th>占比</th>
                                <th style="width: 40%">图示</th>
                            </tr>
                            ${moodStatsHTML}
                        </table>
                    </div>
                    
                    <div class="section">
                        <h2>📝 说明</h2>
                        <p>本报告由「星序」应用自动生成，数据来源于用户的日常使用记录。</p>
                        <p>报告包含任务完成情况和情绪变化趋势，供医生、康复师或教育者参考。</p>
                    </div>
                    
                    <div class="footer">
                        <p>星序 v1.0 | 为自闭症儿童及家长设计</p>
                    </div>
                    
                    <scr"+"ipt>window.onload = function() { setTimeout(function() { window.print(); }, 500); };</scr"+"ipt>
                </body>
                </html>
            `;
        }
        
        // 导出Excel/CSV
        function exportExcel() {
            const csv = generateCSVData();
            const blob = new Blob(['\ufeff' + csv], { type: 'text/csv;charset=utf-8;' });
            const link = document.createElement('a');
            link.href = URL.createObjectURL(blob);
            link.download = `日程数据_${new Date().toLocaleDateString()}.csv`;
            link.click();
            showToast('Excel文件已下载');
        }
        
        function generateCSVData() {
            const headers = ['日期', '时间', '任务名称', '图标', '状态', '成员', '心情'];
            
            // 收集所有数据
            const rows = [];
            
            // 添加任务数据
            tasks.forEach(task => {
                const date = new Date(task.date);
                const dateStr = `${date.getFullYear()}-${String(date.getMonth()+1).padStart(2,'0')}-${String(date.getDate()).padStart(2,'0')}`;
                const member = task.memberId ? getMemberById(task.memberId) : null;
                const memberName = member ? member.name : '';
                const mood = moodData[date.toDateString()];
                const moodEmoji = mood ? MOOD_EMOJIS[mood.level] : '';
                
                rows.push([
                    dateStr,
                    task.time,
                    task.name,
                    task.icon || '',
                    task.completed ? '已完成' : '未完成',
                    memberName,
                    moodEmoji
                ]);
            });
            
            // 按日期排序
            rows.sort((a, b) => a[0].localeCompare(b[0]) || a[1].localeCompare(b[1]));
            
            // 生成CSV
            const csvContent = [
                headers.join(','),
                ...rows.map(row => row.map(cell => `"${cell}"`).join(','))
            ].join('\n');
            
            return csvContent;
        }
        
        // 打印视图
        function openPrintView() {
            const content = generatePrintPreviewHTML();
            document.getElementById('print-preview-content').innerHTML = content;
            document.getElementById('print-modal').classList.add('show');
        }
        
        function closePrintModal(e) {
            if (!e || e.target.id === 'print-modal') {
                document.getElementById('print-modal').classList.remove('show');
            }
        }
        
        function doPrint() {
            window.print();
        }
        
        // ========== 音频导出功能 ==========
        
        // 语音播报今日日程
        function playTodaySchedule() {
            if (!window.speechSynthesis) {
                showToast('您的浏览器不支持语音播报功能');
                return;
            }
            
            const todayTasks = getTasksForDate(currentDate);
            if (todayTasks.length === 0) {
                showToast('今天还没有安排任务');
                return;
            }
            
            // 按时间排序
            const sorted = [...todayTasks].sort((a, b) => a.time.localeCompare(b.time));
            
            // 构建播报文本
            const dateStr = `${currentDate.getMonth() + 1}月${currentDate.getDate()}日`;
            let text = `${dateStr}的日程安排：\n\n`;
            
            sorted.forEach((task, index) => {
                const timeDisplay = task.endTime ? `${task.time}到${task.endTime}` : task.time;
                const status = task.completed ? '已完成' : '待完成';
                text += `${index + 1}、${timeDisplay}，${task.name}，${status}。\n`;
            });
            
            text += `\n共有${sorted.length}个任务，已完成${sorted.filter(t => t.completed).length}个。`;
            
            // 创建语音合成
            const utterance = new SpeechSynthesisUtterance(text);
            utterance.lang = 'zh-CN';
            utterance.rate = 0.9; // 稍慢一点，便于听清
            utterance.pitch = 1;
            
            // 尝试使用更好的中文语音
            const voices = window.speechSynthesis.getVoices();
            const zhVoice = voices.find(v => v.lang.includes('zh') || v.lang.includes('CN'));
            if (zhVoice) {
                utterance.voice = zhVoice;
            }
            
            utterance.onstart = () => {
                showToast('🔊 开始播报今日日程');
            };
            
            utterance.onend = () => {
                showToast('✓ 播报完成');
            };
            
            utterance.onerror = (e) => {
                console.error('语音播报错误:', e);
                showToast('语音播报出错，请重试');
            };
            
            window.speechSynthesis.cancel(); // 停止之前的播报
            window.speechSynthesis.speak(utterance);
        }
        
        // 导出已录制的语音奖励
        function exportAudioRewards() {
            // 查找所有带语音奖励的任务
            const audioTasks = tasks.filter(t => t.rewardType === 'audio' && t.rewardData);
            
            if (audioTasks.length === 0) {
                showToast('没有找到已录制的语音奖励');
                return;
            }
            
            // 如果有多个，提示用户选择
            if (audioTasks.length === 1) {
                downloadAudioFile(audioTasks[0]);
            } else {
                // 显示选择弹窗
                showAudioExportModal(audioTasks);
            }
        }
        
        // 下载单个音频文件
        function downloadAudioFile(task) {
            if (!task.rewardData) {
                showToast('音频数据不存在');
                return;
            }
            
            const date = new Date(task.date);
            const dateStr = `${date.getMonth() + 1}月${date.getDate()}日`;
            const fileName = `语音奖励_${dateStr}_${task.name}.webm`;
            
            const link = document.createElement('a');
            link.href = task.rewardData;
            link.download = fileName;
            link.click();
            
            showToast(`已下载: ${task.name}`);
        }
        
        // 显示音频导出选择弹窗
        function showAudioExportModal(audioTasks) {
            // 创建弹窗HTML
            const modalHTML = `
                <div id="audio-export-modal" class="settings-modal-overlay" style="z-index: 600;" onclick="closeAudioExportModal(event)">
                    <div class="settings-modal" style="max-width: 480px;" onclick="event.stopPropagation()">
                        <div class="settings-header">
                            <h2>导出语音奖励</h2>
                            <button class="close-btn" onclick="closeAudioExportModal()">×</button>
                        </div>
                        <div class="settings-body">
                            <p style="margin-bottom: 16px; color: var(--text-secondary);">
                                找到 ${audioTasks.length} 个语音奖励，请选择要导出的：
                            </p>
                            <div style="display: flex; flex-direction: column; gap: 8px; max-height: 400px; overflow-y: auto;">
                                ${audioTasks.map(task => {
                                    const date = new Date(task.date);
                                    const dateStr = `${date.getMonth() + 1}月${date.getDate()}日`;
                                    const timeDisplay = task.endTime ? `${task.time}-${task.endTime}` : task.time;
                                    return `
                                        <div style="display: flex; align-items: center; gap: 12px; padding: 12px; background: var(--bg-secondary); border-radius: var(--radius); border: 1px solid var(--border);">
                                            <div style="width: 40px; height: 40px; background: var(--accent); border-radius: 50%; display: flex; align-items: center; justify-content: center; color: white; font-size: 18px; flex-shrink: 0;">🎤</div>
                                            <div style="flex: 1; min-width: 0;">
                                                <div style="font-weight: 500; margin-bottom: 2px;">${task.name}</div>
                                                <div style="font-size: 12px; color: var(--text-muted);">${dateStr} ${timeDisplay}</div>
                                            </div>
                                            <button class="btn-primary" onclick="downloadAudioFileFromModal('${task.id}')" style="padding: 8px 16px; font-size: 13px; white-space: nowrap;">下载</button>
                                        </div>
                                    `;
                                }).join('')}
                            </div>
                            <div style="margin-top: 16px; padding-top: 16px; border-top: 1px solid var(--border);">
                                <button class="btn-secondary" onclick="exportAllAudioRewards()" style="width: 100%;">
                                    📦 打包下载全部 (${audioTasks.length}个)
                                </button>
                            </div>
                        </div>
                    </div>
                </div>
            `;
            
            // 移除已存在的弹窗
            const existingModal = document.getElementById('audio-export-modal');
            if (existingModal) existingModal.remove();
            
            // 添加新弹窗
            document.body.insertAdjacentHTML('beforeend', modalHTML);
            document.getElementById('audio-export-modal').classList.add('show');
        }
        
        // 从弹窗下载音频
        function downloadAudioFileFromModal(taskId) {
            const task = tasks.find(t => t.id === taskId);
            if (task) {
                downloadAudioFile(task);
            }
        }
        
        // 关闭音频导出弹窗
        function closeAudioExportModal(e) {
            if (!e || e.target.id === 'audio-export-modal' || e.target.closest('.close-btn')) {
                const modal = document.getElementById('audio-export-modal');
                if (modal) {
                    modal.classList.remove('show');
                    setTimeout(() => modal.remove(), 300);
                }
            }
        }
        
        // 打包下载所有音频（创建一个简单的HTML文件包含所有音频）
        function exportAllAudioRewards() {
            const audioTasks = tasks.filter(t => t.rewardType === 'audio' && t.rewardData);
            
            // 创建包含所有音频的HTML页面
            let audioHTML = `
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>语音奖励合集 - ${new Date().toLocaleDateString()}</title>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; max-width: 800px; margin: 0 auto; padding: 20px; background: #f5f5f5; }
        h1 { text-align: center; color: #333; margin-bottom: 30px; }
        .audio-card { background: white; border-radius: 12px; padding: 20px; margin-bottom: 16px; box-shadow: 0 2px 8px rgba(0,0,0,0.1); }
        .audio-header { display: flex; align-items: center; gap: 12px; margin-bottom: 12px; }
        .audio-icon { width: 48px; height: 48px; background: #000; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-size: 24px; }
        .audio-info { flex: 1; }
        .audio-name { font-size: 18px; font-weight: 600; margin-bottom: 4px; }
        .audio-meta { font-size: 14px; color: #666; }
        audio { width: 100%; margin-top: 8px; }
        .download-btn { display: inline-block; margin-top: 12px; padding: 8px 16px; background: #000; color: white; text-decoration: none; border-radius: 6px; font-size: 14px; }
        .download-btn:hover { background: #333; }
        .total { text-align: center; color: #666; margin-bottom: 20px; }
    </style>
</head>
<body>
    <h1>🎤 语音奖励合集</h1>
    <p class="total">共 ${audioTasks.length} 条语音奖励</p>
`;
            
            audioTasks.forEach((task, index) => {
                const date = new Date(task.date);
                const dateStr = `${date.getFullYear()}年${date.getMonth() + 1}月${date.getDate()}日`;
                const timeDisplay = task.endTime ? `${task.time}-${task.endTime}` : task.time;
                
                audioHTML += `
    <div class="audio-card">
        <div class="audio-header">
            <div class="audio-icon">🎤</div>
            <div class="audio-info">
                <div class="audio-name">${index + 1}. ${task.name}</div>
                <div class="audio-meta">${dateStr} ${timeDisplay}</div>
            </div>
        </div>
        <audio controls src="${task.rewardData}"></audio>
        <a href="${task.rewardData}" download="语音奖励_${task.name}.webm" class="download-btn">⬇️ 下载此音频</a>
    </div>
`;
            });
            
            audioHTML += `
</body>
</html>`;
            
            // 下载HTML文件
            const blob = new Blob([audioHTML], { type: 'text/html;charset=utf-8' });
            const link = document.createElement('a');
            link.href = URL.createObjectURL(blob);
            link.download = `语音奖励合集_${new Date().toLocaleDateString()}.html`;
            link.click();
            
            showToast('📦 语音合集已下载，可用浏览器打开播放');
            closeAudioExportModal();
        }
        
        // ========== 导出到手机日历 (.ics 格式) ==========
        function exportToICal() {
            const icsContent = generateICalData();
            // 使用CRLF换行符（ICS标准要求）
            const icsWithCRLF = icsContent.replace(/\n/g, '\r\n');
            const blob = new Blob([icsWithCRLF], { type: 'text/calendar;charset=utf-8' });
            const link = document.createElement('a');
            link.href = URL.createObjectURL(blob);
            link.download = `星序日程_${new Date().toISOString().split('T')[0]}.ics`;
            link.click();
            showToast('日历文件已下载，可导入手机日历');
        }
        
        function generateICalData() {
            const now = new Date();
            const nowFormatted = formatICalDateUTC(now);
            const childName = currentUser?.childName || currentUser?.username || '孩子';
            
            let events = '';
            let eventCount = 0;
            
            // 过滤未来的任务（30天内）
            const thirtyDaysLater = new Date(now.getTime() + 30 * 24 * 60 * 60 * 1000);
            
            tasks.filter(task => {
                const taskDate = new Date(task.date);
                return taskDate >= now && taskDate <= thirtyDaysLater;
            }).forEach(task => {
                const taskDate = new Date(task.date);
                const dateStr = taskDate.toISOString().split('T')[0].replace(/-/g, '');
                
                // 解析时间
                let startTime = '090000';
                let endTime = '100000';
                let hasTime = false;
                
                if (task.time && task.time.includes(':')) {
                    const [hours, minutes] = task.time.split(':');
                    if (hours && minutes) {
                        startTime = hours.padStart(2, '0') + minutes + '00';
                        // 默认持续1小时
                        const endHour = (parseInt(hours) + 1).toString().padStart(2, '0');
                        endTime = endHour + minutes + '00';
                        hasTime = true;
                    }
                }
                
                const uid = `${task.id || Date.now()}_${eventCount}@xingxu.app`;
                const summary = escapeICalText(`${task.icon || '📋'} ${task.name}`);
                const description = escapeICalText(`任务: ${task.name}\n状态: ${task.completed ? '已完成' : '待完成'}\n来源: 星序APP`);
                
                // 使用本地时间格式（带时区参考）
                const dtStart = hasTime ? `${dateStr}T${startTime}` : `${dateStr}`;
                const dtEnd = hasTime ? `${dateStr}T${endTime}` : `${dateStr}`;
                
                // 如果没有具体时间，使用全天事件（VALUE=DATE）
                const dtStartLine = hasTime 
                    ? `DTSTART;TZID=Asia/Shanghai:${dtStart}` 
                    : `DTSTART;VALUE=DATE:${dateStr}`;
                const dtEndLine = hasTime 
                    ? `DTEND;TZID=Asia/Shanghai:${dtEnd}` 
                    : `DTEND;VALUE=DATE:${dateStr}`;
                
                events += `BEGIN:VEVENT\n`;
                events += `${dtStartLine}\n`;
                events += `${dtEndLine}\n`;
                events += `DTSTAMP:${nowFormatted}\n`;
                events += `UID:${uid}\n`;
                events += `SUMMARY:${summary}\n`;
                events += `DESCRIPTION:${description}\n`;
                events += `STATUS:${task.completed ? 'COMPLETED' : 'CONFIRMED'}\n`;
                events += `END:VEVENT\n`;
                
                eventCount++;
            });
            
            // 如果没有事件，添加一个占位事件避免解析错误
            if (eventCount === 0) {
                const today = now.toISOString().split('T')[0].replace(/-/g, '');
                events = `BEGIN:VEVENT\n`;
                events += `DTSTART;VALUE=DATE:${today}\n`;
                events += `DTEND;VALUE=DATE:${today}\n`;
                events += `DTSTAMP:${nowFormatted}\n`;
                events += `UID:placeholder@xingxu.app\n`;
                events += `SUMMARY:暂无日程\n`;
                events += `DESCRIPTION:暂无未来的日程安排\n`;
                events += `STATUS:CONFIRMED\n`;
                events += `END:VEVENT\n`;
            }
            
            // 构建完整的ICS文件
            let ics = 'BEGIN:VCALENDAR\n';
            ics += 'VERSION:2.0\n';
            ics += 'PRODID:-//星序//孤独症儿童日程管理//EN\n';
            ics += 'CALSCALE:GREGORIAN\n';
            ics += 'METHOD:PUBLISH\n';
            ics += `X-WR-CALNAME:${escapeICalText(childName + '的日程')}\n`;
            ics += 'X-WR-TIMEZONE:Asia/Shanghai\n';
            ics += 'BEGIN:VTIMEZONE\n';
            ics += 'TZID:Asia/Shanghai\n';
            ics += 'X-LIC-LOCATION:Asia/Shanghai\n';
            ics += 'BEGIN:STANDARD\n';
            ics += 'DTSTART:19700101T000000\n';
            ics += 'TZOFFSETFROM:+0800\n';
            ics += 'TZOFFSETTO:+0800\n';
            ics += 'END:STANDARD\n';
            ics += 'END:VTIMEZONE\n';
            ics += events;
            ics += 'END:VCALENDAR';
            
            return ics;
        }
        
        // 格式化UTC时间用于DTSTAMP
        function formatICalDateUTC(date) {
            return date.toISOString().replace(/[-:]/g, '').replace(/\.\d{3}Z/, 'Z');
        }
        
        // 转义ICS文本中的特殊字符
        function escapeICalText(text) {
            if (!text) return '';
            return text
                .replace(/\\/g, '\\\\')
                .replace(/;/g, '\\;')
                .replace(/,/g, '\\,')
                .replace(/\n/g, '\\n')
                .replace(/\r/g, '');
        }
        
        function generatePrintPreviewHTML() {
            const today = new Date();
            const todayStr = today.toDateString();
            const todayTasks = tasks.filter(t => new Date(t.date).toDateString() === todayStr);
            
            // 未来任务
            const futureTasks = tasks.filter(t => new Date(t.date) > today).slice(0, 10);
            
            // 本周情绪
            const weekMoods = [];
            for (let i = 6; i >= 0; i--) {
                const date = new Date();
                date.setDate(date.getDate() - i);
                const mood = moodData[date.toDateString()];
                weekMoods.push({
                    day: ['周日', '周一', '周二', '周三', '周四', '周五', '周六'][date.getDay()],
                    emoji: mood ? MOOD_EMOJIS[mood.level] : '-'
                });
            }
            
            const generateTaskHTML = (taskList) => {
                if (taskList.length === 0) return '<p style="color: #999; text-align: center; padding: 20px;">暂无任务</p>';
                return taskList.map(t => {
                    const member = t.memberId ? getMemberById(t.memberId) : null;
                    const colorStyle = member ? `border-left: 4px solid ${member.color};` : '';
                    return `
                        <div class="print-task-item" style="${colorStyle}">
                            <div class="print-task-checkbox"></div>
                            ${t.image ? `<img src="${t.image}" class="print-task-image">` : ''}
                            <div class="print-task-content">
                                <div class="print-task-name">${t.icon || ''} ${t.name}</div>
                                <div class="print-task-time">${t.time}${member ? ' · ' + member.name : ''}</div>
                            </div>
                        </div>
                    `;
                }).join('');
            };
            
            return `
                <div class="print-preview">
                    <div class="print-header">
                        <h1>📋 今日日程表</h1>
                        <div class="print-date">${today.getFullYear()}年${today.getMonth()+1}月${today.getDate()}日 ${['周日','周一','周二','周三','周四','周五','周六'][today.getDay()]}</div>
                    </div>
                    
                    <div class="print-section">
                        <h3>📋 今日待办任务</h3>
                        <div class="print-task-list">
                            ${generateTaskHTML(todayTasks)}
                        </div>
                    </div>
                    
                    <div class="print-section">
                        <h3>🗓️ 即将到来的任务</h3>
                        <div class="print-task-list">
                            ${generateTaskHTML(futureTasks)}
                        </div>
                    </div>
                    
                    <div class="print-section">
                        <h3>😊 本周心情记录</h3>
                        <div class="print-mood-grid">
                            ${weekMoods.map(m => `<div class="print-mood-day">${m.day}<br>${m.emoji}</div>`).join('')}
                        </div>
                    </div>
                    
                    <div class="print-section" style="margin-top: 40px; padding-top: 20px; border-top: 1px dashed #ccc;">
                        <p style="font-size: 12px; color: #999; text-align: center;">
                            打印时间：${new Date().toLocaleString()} | 星序应用
                        </p>
                    </div>
                </div>
            `;
        }
        
        // ========== 日记功能 ==========
        let diaries = {};  // 格式: { '2024-01-01': '日记内容' }
        
        // ========== 情绪功能 ==========
        let moodData = {};  // 格式: { 'Mon Jan 01 2024': { level: 3, note: '备注' } }
        
        // 加载情绪数据
        function loadMoodData() {
            try {
                const saved = localStorage.getItem(getMoodKey());
                if (saved) {
                    moodData = JSON.parse(saved);
                } else {
                    moodData = {};
                }
            } catch (e) {
                console.error('加载情绪数据失败:', e);
                moodData = {};
            }
        }
        
        // 保存情绪数据
        function saveMoodData() {
            try {
                localStorage.setItem(getMoodKey(), JSON.stringify(moodData));
            } catch (e) {
                console.error('保存情绪数据失败:', e);
            }
        }
        
        // ========== 团队功能 ==========
        let selectedColor = '#FF6B6B';
        
        function toggleTeamMode() {
            appSettings.teamMode = document.getElementById('team-mode-enabled').checked;
            const section = document.getElementById('team-members-section');
            if (section) {
                section.style.display = appSettings.teamMode ? 'block' : 'none';
            }
            
            // 如果启用团队模式但没有成员，添加一个默认成员（当前用户）
            if (appSettings.teamMode && appSettings.teamMembers.length === 0) {
                const defaultMember = {
                    id: 'member_' + Date.now(),
                    name: currentUser ? currentUser.username : '我',
                    color: '#FF6B6B'
                };
                appSettings.teamMembers = [defaultMember];
                appSettings.currentMemberId = defaultMember.id;
            }
            
            updateTeamMembersUI();
            renderAll(); // 重新渲染任务列表
        }
        
        function updateTeamMembersUI() {
            const listEl = document.getElementById('team-members-list');
            const selectEl = document.getElementById('current-member-select');
            
            if (!listEl || !selectEl) return;
            
            // 更新成员列表
            listEl.innerHTML = appSettings.teamMembers.map(member => `
                <div class="team-member-item">
                    <div class="member-color-dot" style="background: ${member.color};"></div>
                    <span class="member-name">${escapeHtml(member.name)}</span>
                    ${member.id === appSettings.currentMemberId ? '<span class="member-current-badge">当前</span>' : ''}
                    <button class="member-delete-btn" onclick="deleteTeamMember('${member.id}')" title="删除">×</button>
                </div>
            `).join('');
            
            // 更新下拉选择
            const currentValue = selectEl.value;
            selectEl.innerHTML = '<option value="">请选择当前用户</option>' +
                appSettings.teamMembers.map(member => 
                    `<option value="${member.id}" ${member.id === appSettings.currentMemberId ? 'selected' : ''}>${escapeHtml(member.name)}</option>`
                ).join('');
        }
        
        function openAddMemberModal() {
            document.getElementById('add-member-modal').classList.add('show');
            document.getElementById('new-member-name').value = '';
            selectedColor = '#FF6B6B';
            updateColorPickerUI();
        }
        
        function closeAddMemberModal(e) {
            if (!e || e.target.id === 'add-member-modal') {
                document.getElementById('add-member-modal').classList.remove('show');
            }
        }
        
        function selectColor(color) {
            selectedColor = color;
            updateColorPickerUI();
        }
        
        function updateColorPickerUI() {
            document.querySelectorAll('.color-option').forEach(option => {
                option.classList.toggle('active', option.dataset.color === selectedColor);
            });
        }
        
        function addTeamMember() {
            const name = document.getElementById('new-member-name').value.trim();
            if (!name) {
                showToast('请输入成员姓名');
                return;
            }
            
            // 检查是否重名
            if (appSettings.teamMembers.some(m => m.name === name)) {
                showToast('该姓名已存在');
                return;
            }
            
            const newMember = {
                id: 'member_' + Date.now(),
                name: name,
                color: selectedColor
            };
            
            appSettings.teamMembers.push(newMember);
            
            // 如果是第一个成员，设为当前用户
            if (appSettings.teamMembers.length === 1) {
                appSettings.currentMemberId = newMember.id;
            }
            
            updateTeamMembersUI();
            closeAddMemberModal();
            showToast('成员添加成功');
        }
        
        function deleteTeamMember(memberId) {
            if (appSettings.teamMembers.length <= 1) {
                showToast('至少需要保留一个成员');
                return;
            }
            
            if (!confirm('确定要删除该成员吗？该成员的任务将保留但不再显示其标识。')) {
                return;
            }
            
            appSettings.teamMembers = appSettings.teamMembers.filter(m => m.id !== memberId);
            
            // 如果删除的是当前用户，重置当前用户
            if (appSettings.currentMemberId === memberId) {
                appSettings.currentMemberId = appSettings.teamMembers[0]?.id || null;
            }
            
            updateTeamMembersUI();
            renderAll();
            showToast('成员已删除');
        }
        
        function switchCurrentMember() {
            const selectEl = document.getElementById('current-member-select');
            appSettings.currentMemberId = selectEl.value || null;
            updateTeamMembersUI();
            renderAll();
        }
        
        function getMemberById(memberId) {
            return appSettings.teamMembers.find(m => m.id === memberId);
        }
        
        function getCurrentMember() {
            return getMemberById(appSettings.currentMemberId);
        }
        
        function escapeHtml(text) {
            const div = document.createElement('div');
            div.textContent = text;
            return div.innerHTML;
        }
        
        function changeAvatar() {
            document.getElementById('settings-avatar-input').click();
        }
        
        function handleSettingsAvatarUpload(event) {
            const file = event.target.files[0];
            if (!file) return;
            
            if (file.size > 2 * 1024 * 1024) {
                showToast('图片大小不能超过2MB');
                return;
            }
            
            const reader = new FileReader();
            reader.onload = function(e) {
                settingsTempAvatar = e.target.result;
                const avatarEl = document.getElementById('settings-avatar');
                avatarEl.innerHTML = `<img src="${settingsTempAvatar}" alt="头像">`;
            };
            reader.readAsDataURL(file);
        }
        
        function openCityModalFromSettings() {
            closeSettingsModal();
            openCityModal();
        }
        
        function exportData() {
            const data = {
                tasks: tasks,
                settings: appSettings,
                moodData: moodData,
                exportDate: new Date().toISOString()
            };
            const blob = new Blob([JSON.stringify(data, null, 2)], { type: 'application/json' });
            const url = URL.createObjectURL(blob);
            const a = document.createElement('a');
            a.href = url;
            a.download = `星序备份_${new Date().toISOString().split('T')[0]}.json`;
            a.click();
            URL.revokeObjectURL(url);
            showToast('数据已导出');
        }
        
        function handleImportFile(input) {
            const file = input.files[0];
            if (!file) return;
            
            if (!file.name.endsWith('.json')) {
                showToast('请选择 JSON 格式的备份文件');
                input.value = '';
                return;
            }
            
            const reader = new FileReader();
            reader.onload = function(e) {
                try {
                    const data = JSON.parse(e.target.result);
                    
                    // 验证数据格式
                    if (!data || typeof data !== 'object') {
                        throw new Error('无效的备份文件格式');
                    }
                    
                    // 确认导入
                    if (!confirm(`确定要导入这个备份文件吗？\n\n文件信息:\n- 文件名: ${file.name}\n- 导出时间: ${data.exportDate ? new Date(data.exportDate).toLocaleString() : '未知'}\n\n注意: 导入将覆盖当前所有数据！`)) {
                        input.value = '';
                        return;
                    }
                    
                    // 导入任务
                    if (data.tasks && Array.isArray(data.tasks)) {
                        tasks = data.tasks;
                        saveTasks();
                    }
                    
                    // 导入设置
                    if (data.settings && typeof data.settings === 'object') {
                        appSettings = { ...appSettings, ...data.settings };
                        localStorage.setItem(getSettingsKey(), JSON.stringify(appSettings));
                        applySettings();
                    }
                    
                    // 导入心情数据
                    if (data.moodData && typeof data.moodData === 'object') {
                        moodData = data.moodData;
                        saveMoodData();
                    }
                    
                    showToast('备份文件导入成功，即将刷新...');
                    setTimeout(() => location.reload(), 1500);
                    
                } catch (err) {
                    console.error('导入失败:', err);
                    showToast('导入失败: ' + (err.message || '文件格式无效'));
                } finally {
                    input.value = '';
                }
            };
            reader.onerror = function() {
                showToast('读取文件失败');
                input.value = '';
            };
            reader.readAsText(file);
        }
        
        function clearAllData() {
            if (!confirm('确定要清空所有数据吗？\n\n这将删除：\n- 所有任务\n- 所有设置\n- 登录状态\n- 心情记录\n- 云端备份\n\n此操作不可撤销！')) return;
            
            // 删除当前用户的数据（使用用户隔离的key）
            localStorage.removeItem(getTasksKey());
            localStorage.removeItem(getDiaryStorageKey());
            localStorage.removeItem(getMoodKey());
            
            // 删除全局设置和认证信息
            localStorage.removeItem(getSettingsKey());
            localStorage.removeItem(AUTH_KEY);
            localStorage.removeItem(WEATHER_KEY);
            localStorage.removeItem(getHelpKey());
            localStorage.removeItem(getCloudKey());
            localStorage.removeItem(getCloudMetaKey());
            localStorage.removeItem(PREMIUM_KEY);
            
            showToast('数据已清空，即将刷新...');
            setTimeout(() => location.reload(), 1500);
        }
        
        // ========== 云同步功能 (MVP版本) ==========
        // 使用localStorage模拟云端，后续可替换为真实API
        
        // 更新云同步UI状态
        function updateCloudSyncUI() {
            const statusEl = document.getElementById('cloud-status');
            const uploadBtn = document.getElementById('btn-cloud-upload');
            const downloadBtn = document.getElementById('btn-cloud-download');
            
            if (!statusEl) return;
            
            if (!currentUser) {
                statusEl.textContent = '请先登录';
                if (uploadBtn) uploadBtn.style.opacity = '0.5';
                if (downloadBtn) downloadBtn.style.opacity = '0.5';
                return;
            }
            
            if (!isPremiumUser()) {
                statusEl.innerHTML = '⭐ <b>敬请期待</b> - 高级功能即将开放';
                statusEl.style.color = '#d97706';
                if (uploadBtn) uploadBtn.style.opacity = '0.5';
                if (downloadBtn) downloadBtn.style.opacity = '0.5';
                return;
            }
            
            // VIP用户显示实际状态
            const status = CloudSync.getStatus();
            if (status.synced) {
                const syncTime = new Date(status.lastSync).toLocaleString();
                const deviceText = status.isThisDevice ? '本机' : '其他设备';
                statusEl.innerHTML = `✅ <b>已同步</b> - ${syncTime} (${deviceText})`;
                statusEl.style.color = '#059669';
                if (uploadBtn) uploadBtn.style.opacity = '1';
                if (downloadBtn) downloadBtn.style.opacity = '1';
            } else {
                statusEl.innerHTML = '📤 <b>未同步</b> - 点击上传按钮备份数据';
                statusEl.style.color = '#6b7280';
                if (uploadBtn) uploadBtn.style.opacity = '1';
                if (downloadBtn) downloadBtn.style.opacity = '0.5';
            }
        }
        
        const CloudSync = {
            // 上传数据到"云端"
            upload() {
                if (!isPremiumUser()) {
                    showToast('云同步功能 - 敬请期待', 3000);
                    return Promise.resolve(false);
                }
                
                try {
                    const data = {
                        tasks: tasks,
                        settings: appSettings,
                        moodData: moodData,
                        templates: JSON.parse(localStorage.getItem(getTemplatesKey()) || '[]'),
                        uploadTime: new Date().toISOString(),
                        deviceId: this.getDeviceId()
                    };
                    
                    localStorage.setItem(getCloudKey(), JSON.stringify(data));
                    localStorage.setItem(getCloudMetaKey(), JSON.stringify({
                        lastSync: new Date().toISOString(),
                        deviceId: this.getDeviceId()
                    }));
                    
                    updateCloudSyncUI();
                    showToast('数据已同步到云端');
                    return Promise.resolve(true);
                } catch (e) {
                    console.error('云同步失败:', e);
                    showToast('同步失败: ' + e.message);
                    return Promise.resolve(false);
                }
            },
            
            // 从"云端"下载数据
            download() {
                if (!isPremiumUser()) {
                    showToast('云同步功能 - 敬请期待', 3000);
                    return Promise.resolve(false);
                }
                
                try {
                    const cloudData = localStorage.getItem(getCloudKey());
                    if (!cloudData) {
                        showToast('云端没有数据');
                        return Promise.resolve(false);
                    }
                    
                    const data = JSON.parse(cloudData);
                    
                    if (confirm(`发现云端备份\n备份时间: ${new Date(data.uploadTime).toLocaleString()}\n\n确定要恢复吗？这将覆盖当前数据！`)) {
                        tasks = data.tasks || [];
                        if (data.settings) {
                            appSettings = { ...appSettings, ...data.settings };
                            localStorage.setItem(getSettingsKey(), JSON.stringify(appSettings));
                        }
                        if (data.moodData) {
                            moodData = data.moodData;
                            saveMoodData();
                        }
                        if (data.templates) {
                            localStorage.setItem(getTemplatesKey(), JSON.stringify(data.templates));
                        }
                        
                        saveTasks();
                        renderAll();
                        updateCloudSyncUI();
                        showToast('数据已从云端恢复');
                        return Promise.resolve(true);
                    }
                    return Promise.resolve(false);
                } catch (e) {
                    console.error('下载失败:', e);
                    showToast('下载失败: ' + e.message);
                    return Promise.resolve(false);
                }
            },
            
            // 获取同步状态
            getStatus() {
                const meta = localStorage.getItem(getCloudMetaKey());
                if (!meta) return { synced: false, lastSync: null };
                const parsed = JSON.parse(meta);
                return {
                    synced: true,
                    lastSync: parsed.lastSync,
                    isThisDevice: parsed.deviceId === this.getDeviceId()
                };
            },
            
            // 获取设备ID
            getDeviceId() {
                let deviceId = localStorage.getItem('schedule-device-id');
                if (!deviceId) {
                    deviceId = 'device_' + Date.now() + '_' + Math.random().toString(36).substr(2, 9);
                    localStorage.setItem('schedule-device-id', deviceId);
                }
                return deviceId;
            },
            
            // 自动同步（开发中）
            async autoSync() {
                if (!isPremiumUser()) return;
                // MVP版本不实现自动同步，需要用户手动点击
            }
        };
        
        // ========== 高级报表功能 (给医生的专业报告) ==========
        const AdvancedReport = {
            // 检查权限
            checkAccess() {
                return checkPremiumFeature('高级分析报表');
            },
            
            // 生成专业报告
            generate() {
                if (!this.checkAccess()) return null;
                
                const now = new Date();
                const thirtyDaysAgo = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
                
                // 过滤30天的数据
                const recentTasks = tasks.filter(t => new Date(t.date) >= thirtyDaysAgo);
                const recentMoods = Object.entries(moodData).filter(([date]) => new Date(date) >= thirtyDaysAgo);
                
                // 统计分析
                const stats = this.analyzeData(recentTasks, recentMoods);
                
                return {
                    generatedAt: now.toISOString(),
                    period: `${thirtyDaysAgo.toLocaleDateString()} 至 ${now.toLocaleDateString()}`,
                    summary: stats,
                    recommendations: this.generateRecommendations(stats)
                };
            },
            
            // 数据分析
            analyzeData(tasks, moods) {
                const totalTasks = tasks.length;
                const completedTasks = tasks.filter(t => t.completed).length;
                const completionRate = totalTasks > 0 ? (completedTasks / totalTasks * 100).toFixed(1) : 0;
                
                // 时间分布分析
                const timeDistribution = {};
                tasks.forEach(t => {
                    const hour = t.time?.split(':')[0] || 'unknown';
                    timeDistribution[hour] = (timeDistribution[hour] || 0) + 1;
                });
                
                // 心情趋势分析
                const moodTrends = { 1: 0, 2: 0, 3: 0, 4: 0, 5: 0 };
                let totalMood = 0;
                moods.forEach(([_, mood]) => {
                    moodTrends[mood.level] = (moodTrends[mood.level] || 0) + 1;
                    totalMood += parseInt(mood.level);
                });
                const avgMood = moods.length > 0 ? (totalMood / moods.length).toFixed(1) : 0;
                
                // 寻找最佳/最差时段
                let bestHour = null, worstHour = null;
                const hourCompletion = {};
                tasks.forEach(t => {
                    if (!t.time) return;
                    const hour = t.time.split(':')[0];
                    if (!hourCompletion[hour]) hourCompletion[hour] = { total: 0, completed: 0 };
                    hourCompletion[hour].total++;
                    if (t.completed) hourCompletion[hour].completed++;
                });
                
                let bestRate = -1, worstRate = 101;
                Object.entries(hourCompletion).forEach(([hour, data]) => {
                    const rate = data.completed / data.total;
                    if (rate > bestRate) { bestRate = rate; bestHour = hour; }
                    if (rate < worstRate) { worstRate = rate; worstHour = hour; }
                });
                
                return {
                    totalTasks,
                    completedTasks,
                    completionRate,
                    avgMood,
                    moodTrends,
                    timeDistribution,
                    bestHour: bestHour ? `${bestHour}:00` : null,
                    bestHourRate: bestRate >= 0 ? (bestRate * 100).toFixed(0) : null,
                    worstHour: worstHour ? `${worstHour}:00` : null,
                    worstHourRate: worstRate <= 100 ? (worstRate * 100).toFixed(0) : null,
                    moodCount: moods.length
                };
            },
            
            // 生成建议
            generateRecommendations(stats) {
                const recs = [];
                
                if (stats.completionRate < 50) {
                    recs.push('任务完成率较低，建议减少每日任务数量，从最重要的开始');
                } else if (stats.completionRate > 85) {
                    recs.push('任务完成率很高，可以适当增加任务难度或数量');
                }
                
                if (stats.avgMood < 3) {
                    recs.push('近期心情评分较低，建议增加奖励活动，或调整任务强度');
                }
                
                if (stats.worstHour) {
                    recs.push(`${stats.worstHour}时段任务完成率较低，建议调整该时段的任务安排`);
                }
                
                if (stats.bestHour) {
                    recs.push(`${stats.bestHour}是完成任务的黄金时段，建议将重要任务安排在这个时间`);
                }
                
                if (stats.moodCount < 10) {
                    recs.push('心情记录较少，建议每日为孩子记录心情，便于发现规律');
                }
                
                return recs;
            },
            
            // 导出PDF报告
            exportPDF() {
                const report = this.generate();
                if (!report) return;
                
                const userName = currentUser?.username || '用户';
                const childName = currentUser?.childName || '孩子';
                
                let content = `
<h1>🌟 星序 - 专业分析报告</h1>
<h2>报告信息</h2>
<p><strong>孩子姓名:</strong> ${childName}</p>
<p><strong>报告生成时间:</strong> ${new Date(report.generatedAt).toLocaleString()}</p>
<p><strong>分析周期:</strong> ${report.period}</p>

<h2>📊 数据概览</h2>
<ul>
<li>总任务数: ${report.summary.totalTasks}</li>
<li>已完成: ${report.summary.completedTasks}</li>
<li>完成率: ${report.summary.completionRate}%</li>
<li>平均心情: ${report.summary.avgMood}/5</li>
<li>心情记录天数: ${report.summary.moodCount}</li>
</ul>

<h2>📈 时间分布分析</h2>
<p>黄金时段: ${report.summary.bestHour || '暂无数据'} (${report.summary.bestHourRate || 0}% 完成率)</p>
<p>需改进时段: ${report.summary.worstHour || '暂无数据'} (${report.summary.worstHourRate || 0}% 完成率)</p>

<h2>💡 专家建议</h2>
<ul>
${report.recommendations.map(r => `<li>${r}</li>`).join('')}
</ul>

<h2>📝 医生备注</h2>
<p style="border: 1px solid #ccc; padding: 20px; min-height: 100px;">
_________________________________<br>
签名: _________________ 日期: _______________
</p>

<p style="color: #666; font-size: 12px; margin-top: 40px;">
本报告由星序APP自动生成，仅供参考。<br>
数据来源: ${window.location.href}
</p>
                `;
                
                this.printReport(content, `${childName}_专业分析报告_${new Date().toISOString().split('T')[0]}.pdf`);
            },
            
            // 打印报告
            printReport(content, filename) {
                const printWindow = window.open('', '_blank');
                printWindow.document.write(`
                    <!DOCTYPE html>
                    <html>
                    <head>
                        <meta charset="UTF-8">
                        <title>专业分析报告</title>
                        <style>
                            body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; padding: 40px; max-width: 800px; margin: 0 auto; }
                            h1 { color: #111827; border-bottom: 3px solid #000; padding-bottom: 10px; }
                            h2 { color: #374151; margin-top: 30px; }
                            ul { line-height: 1.8; }
                            li { margin-bottom: 8px; }
                            p { line-height: 1.6; }
                            @media print { body { padding: 20px; } }
                        </style>
                    </head>
                    <body>${content}</body>
                    </html>
                `);
                printWindow.document.close();
                setTimeout(() => {
                    printWindow.print();
                }, 500);
            }
        };
        
        // ========== 认证功能 ==========
        const AUTH_KEY = 'schedule-auth';
        // 云端数据存储key - 用户隔离
        function getCloudKey() {
            return getUserStorageKey('schedule-cloud-data');
        }
        
        function getCloudMetaKey() {
            return getUserStorageKey('schedule-cloud-meta');
        }
        
        const PREMIUM_KEY = 'schedule-premium-status'; // 付费用户状态（全局）
        
        let currentUser = null;
        let tempAvatarData = null;
        
        // ========== 权限控制 ==========
        const PREMIUM_USER = 'JUNNY张琦';  // VIP账号
        
        function isPremiumUser() {
            return currentUser && currentUser.username === PREMIUM_USER;
        }
        
        function checkPremiumFeature(featureName) {
            if (!isPremiumUser()) {
                showToast(`${featureName} - 敬请期待`, 3000);
                return false;
            }
            return true;
        }
        
        // 头像上传处理
        function handleAvatarUpload(event) {
            const file = event.target.files[0];
            if (!file) return;
            
            if (file.size > 2 * 1024 * 1024) {
                showToast('图片大小不能超过2MB');
                return;
            }
            
            const reader = new FileReader();
            reader.onload = function(e) {
                tempAvatarData = e.target.result;
                const preview = document.getElementById('avatar-preview');
                preview.innerHTML = `<img src="${tempAvatarData}" alt="头像">`;
            };
            reader.readAsDataURL(file);
        }
        
        // 获取用户偏好设置
        function getUserPreferences() {
            const timeFormat = document.querySelector('input[name="time-format"]:checked')?.value || '24h';
            const weekStart = document.querySelector('input[name="week-start"]:checked')?.value || 'monday';
            const defaultView = document.getElementById('default-view')?.value || 'day';
            
            return { timeFormat, weekStart, defaultView };
        }
        
        function initAuth() {
            const authData = localStorage.getItem(AUTH_KEY);
            if (authData) {
                try {
                    const auth = JSON.parse(authData);
                    if (auth.isLoggedIn && auth.user) {
                        currentUser = auth.user;
                        
                        // 加载用户设置
                        const savedSettings = localStorage.getItem('schedule-settings-' + currentUser.username);
                        if (savedSettings) {
                            appSettings = JSON.parse(savedSettings);
                            // 应用主题
                            document.documentElement.setAttribute('data-theme', appSettings.theme || 'light');
                            // 应用字体大小
                            document.body.classList.remove('font-small', 'font-normal', 'font-large');
                            document.body.classList.add('font-' + (appSettings.fontSize || 'normal'));
                        }
                        
                        // 重新加载当前用户的数据
                        reloadUserData();
                        
                        // 显示主界面
                        document.getElementById('auth-page').classList.add('hidden');
                        document.getElementById('main-app').classList.remove('hidden');
                        updateUserInfo();
                        renderAll();
                        return;
                    }
                } catch (e) {
                    console.error('初始化失败:', e);
                    localStorage.removeItem(AUTH_KEY);
                }
            }
            
            // 显示登录页
            document.getElementById('auth-page').classList.remove('hidden');
            document.getElementById('main-app').classList.add('hidden');
        }
        
        // 重新加载当前用户的所有数据
        function reloadUserData() {
            tasks = getTasks();
            loadDiaries();
            loadMoodData();
            renderAll();
        }
        
        function showAuthPage() {
            document.getElementById('auth-page').classList.remove('hidden');
            document.getElementById('main-app').classList.add('hidden');
        }
        
        function showMainApp() {
            document.getElementById('auth-page').classList.add('hidden');
            document.getElementById('main-app').classList.remove('hidden');
            updateUserInfo();
        }
        
        function updateUserInfo() {
            if (currentUser) {
                document.getElementById('user-name').textContent = currentUser.username;
                const avatarEl = document.getElementById('user-avatar');
                if (currentUser.avatar) {
                    avatarEl.innerHTML = `<img src="${currentUser.avatar}" alt="头像">`;
                } else {
                    avatarEl.textContent = currentUser.username.charAt(0).toUpperCase();
                }
            }
        }

        function handleLogin() {
            const username = document.getElementById('login-username').value.trim();
            const password = document.getElementById('login-password').value;
            
            if (!username || !password) {
                showToast('请输入用户名和密码');
                return;
            }
            
            const users = JSON.parse(localStorage.getItem('schedule-users') || '[]');
            const user = users.find(u => u.username === username && u.password === password);
            
            if (user) {
                currentUser = user;
                localStorage.setItem(AUTH_KEY, JSON.stringify({ isLoggedIn: true, user }));
                
                // 加载用户设置
                const savedSettings = localStorage.getItem('schedule-settings-' + username);
                if (savedSettings) {
                    appSettings = JSON.parse(savedSettings);
                    // 应用主题
                    document.documentElement.setAttribute('data-theme', appSettings.theme || 'light');
                    // 应用字体大小
                    document.body.classList.remove('font-small', 'font-normal', 'font-large');
                    document.body.classList.add('font-' + (appSettings.fontSize || 'normal'));
                }
                
                // 重新加载该用户的数据
                reloadUserData();
                
                // 显示主界面
                document.getElementById('auth-page').classList.add('hidden');
                document.getElementById('main-app').classList.remove('hidden');
                updateUserInfo();
                renderAll();
                
                showToast('欢迎回来，' + username);
            } else {
                showToast('用户名或密码错误');
            }
        }
        
        function handleRegister() {
            const username = document.getElementById('register-username').value.trim();
            const password = document.getElementById('register-password').value;
            const confirm = document.getElementById('register-confirm').value;
            
            if (!username || !password) {
                showToast('请输入用户名和密码');
                return;
            }
            
            if (password !== confirm) {
                showToast('两次输入的密码不一致');
                return;
            }
            
            if (password.length < 6) {
                showToast('密码长度至少6位');
                return;
            }
            
            const users = JSON.parse(localStorage.getItem('schedule-users') || '[]');
            if (users.find(u => u.username === username)) {
                showToast('用户名已存在');
                return;
            }
            
            // 获取偏好设置
            const preferences = getUserPreferences();
            
            const newUser = { 
                username, 
                password,
                avatar: tempAvatarData,
                preferences
            };
            users.push(newUser);
            localStorage.setItem('schedule-users', JSON.stringify(users));
            
            currentUser = newUser;
            tempAvatarData = null;
            localStorage.setItem(AUTH_KEY, JSON.stringify({ isLoggedIn: true, user: newUser }));
            
            // 初始化新用户的默认设置（简单版本）
            const defaultSettings = {
                mode: 'parent',
                theme: 'light',
                fontSize: 'normal',
                timeFormat: preferences.timeFormat || '24h',
                weekStart: preferences.weekStart || 'monday',
                defaultView: 'day',
                autoLocate: false,
                showHelpOnStart: true,
                teamMode: false,
                teamMembers: [],
                currentMemberId: null,
                childSettings: {
                    showWeather: true,
                    showImages: true,
                    colorCoding: true,
                    largeCards: true,
                    voicePrompts: true
                },
                completeSound: true
            };
            
            // 保存设置
            localStorage.setItem('schedule-settings-' + username, JSON.stringify(defaultSettings));
            
            // 更新当前设置
            appSettings = defaultSettings;
            
            // 应用主题和字体
            document.documentElement.setAttribute('data-theme', 'light');
            document.body.classList.remove('font-small', 'font-normal', 'font-large');
            document.body.classList.add('font-normal');
            
            // 显示主界面
            document.getElementById('auth-page').classList.add('hidden');
            document.getElementById('main-app').classList.remove('hidden');
            
            // 更新用户信息
            updateUserInfo();
            
            // 重新渲染
            renderAll();
            
            showToast('注册成功');
        }
        
        function handleLogout() {
            // 保存当前用户的数据（确保数据不会丢失）
            saveTasks();
            saveDiaries();
            saveMoodData();
            
            // 清除当前用户状态
            currentUser = null;
            tasks = [];
            diaries = {};
            moodData = {};
            
            localStorage.removeItem(AUTH_KEY);
            showAuthPage();
            document.getElementById('login-username').value = '';
            document.getElementById('login-password').value = '';
            showToast('已退出登录');
            updateCloudSyncUI();
        }
        
        // 登录/注册表单回车提交
        document.getElementById('login-password').addEventListener('keypress', (e) => {
            if (e.key === 'Enter') handleLogin();
        });
        document.getElementById('register-confirm').addEventListener('keypress', (e) => {
            if (e.key === 'Enter') handleRegister();
        });
        
        // ========== 任务模板功能 ==========
        let customTemplates = {};
        let editingTemplateId = null;
        
        function getTemplates() {
            const saved = localStorage.getItem(getTemplatesKey());
            if (saved) {
                customTemplates = JSON.parse(saved);
            }
            return { ...DEFAULT_TEMPLATES, ...customTemplates };
        }
        
        function saveTemplates() {
            localStorage.setItem(getTemplatesKey(), JSON.stringify(customTemplates));
        }
        
        function applyTemplate(templateId) {
            const templates = getTemplates();
            const template = templates[templateId];
            if (!template) return;
            
            // 确认是否应用
            if (!confirm(`应用模板"${template.name}"？\n将添加 ${template.tasks.length} 个任务到今天的日程。`)) {
                return;
            }
            
            // 获取今天的日期
            const today = new Date();
            const dateStr = today.toISOString().split('T')[0];
            
            // 添加模板中的任务
            template.tasks.forEach((task, index) => {
                const newTask = {
                    id: Date.now().toString() + '_' + index,
                    name: task.name,
                    time: task.time,
                    icon: task.icon || '',
                    image: task.image || '',
                    date: today.toISOString(),
                    completed: false
                };
                
                if (appSettings.teamMode && appSettings.currentMemberId) {
                    newTask.memberId = appSettings.currentMemberId;
                }
                
                tasks.push(newTask);
            });
            
            saveTasks();
            renderAll();
            showToast(`已应用模板：${template.name}`);
        }
        
        function openTemplateManager() {
            renderTemplateManageList();
            openSettingsModal();
            // 滚动到模板设置区域
            setTimeout(() => {
                const templateSection = document.querySelector('.template-manage-list');
                if (templateSection) {
                    templateSection.scrollIntoView({ behavior: 'smooth', block: 'center' });
                }
            }, 100);
        }
        
        function renderTemplateManageList() {
            const listEl = document.getElementById('template-manage-list');
            if (!listEl) return;
            
            const templates = getTemplates();
            
            if (Object.keys(templates).length === 0) {
                listEl.innerHTML = '<p style="color: var(--text-muted); text-align: center; padding: 20px;">暂无模板</p>';
                return;
            }
            
            listEl.innerHTML = Object.values(templates).map(template => `
                <div class="template-manage-item">
                    <div class="template-manage-info">
                        <span class="template-manage-icon">${template.icon || '📋'}</span>
                        <div>
                            <div class="template-manage-name">${escapeHtml(template.name)}</div>
                            <div class="template-manage-count">${template.tasks.length} 个任务</div>
                        </div>
                    </div>
                    <div class="template-manage-actions">
                        ${template.isDefault ? '' : `
                            <button class="btn-edit" onclick="editTemplate('${template.id}')">编辑</button>
                            <button class="btn-delete" onclick="deleteTemplate('${template.id}')">删除</button>
                        `}
                        <button class="btn-edit" onclick="applyTemplate('${template.id}'); closeSettingsModal();">应用</button>
                    </div>
                </div>
            `).join('');
        }
        
        function openCreateTemplateModal() {
            editingTemplateId = null;
            document.getElementById('template-modal-title').textContent = '创建任务模板';
            document.getElementById('template-name').value = '';
            document.getElementById('template-icon').value = '📋';
            document.getElementById('template-tasks-list').innerHTML = '';
            
            // 添加两个空任务项
            addTemplateTask();
            addTemplateTask();
            
            document.getElementById('template-modal').classList.add('show');
        }
        
        function editTemplate(templateId) {
            const templates = getTemplates();
            const template = templates[templateId];
            if (!template || template.isDefault) return;
            
            editingTemplateId = templateId;
            document.getElementById('template-modal-title').textContent = '编辑任务模板';
            document.getElementById('template-name').value = template.name;
            document.getElementById('template-icon').value = template.icon || '📋';
            
            // 渲染任务列表
            const listEl = document.getElementById('template-tasks-list');
            listEl.innerHTML = '';
            template.tasks.forEach(task => {
                addTemplateTask(task.name, task.time, task.icon);
            });
            
            document.getElementById('template-modal').classList.add('show');
        }
        
        function addTemplateTask(name = '', time = '09:00', icon = '') {
            const listEl = document.getElementById('template-tasks-list');
            const taskDiv = document.createElement('div');
            taskDiv.className = 'template-task-item';
            taskDiv.innerHTML = `
                <input type="text" placeholder="任务名称" value="${escapeHtml(name)}" class="template-task-name">
                <input type="time" value="${time}" class="template-task-time">
                <select class="template-task-icon">
                    <option value="" ${!icon ? 'selected' : ''}>无</option>
                    <option value="🪥" ${icon === '🪥' ? 'selected' : ''}>🪥</option>
                    <option value="🍽️" ${icon === '🍽️' ? 'selected' : ''}>🍽️</option>
                    <option value="📚" ${icon === '📚' ? 'selected' : ''}>📚</option>
                    <option value="💼" ${icon === '💼' ? 'selected' : ''}>💼</option>
                    <option value="🏃" ${icon === '🏃' ? 'selected' : ''}>🏃</option>
                    <option value="💊" ${icon === '💊' ? 'selected' : ''}>💊</option>
                    <option value="🛏️" ${icon === '🛏️' ? 'selected' : ''}>🛏️</option>
                    <option value="🎒" ${icon === '🎒' ? 'selected' : ''}>🎒</option>
                    <option value="✏️" ${icon === '✏️' ? 'selected' : ''}>✏️</option>
                    <option value="👕" ${icon === '👕' ? 'selected' : ''}>👕</option>
                    <option value="🛁" ${icon === '🛁' ? 'selected' : ''}>🛁</option>
                </select>
                <button type="button" class="template-task-remove" onclick="this.parentElement.remove()">×</button>
            `;
            listEl.appendChild(taskDiv);
        }
        
        function saveTemplate() {
            const name = document.getElementById('template-name').value.trim();
            const icon = document.getElementById('template-icon').value;
            
            if (!name) {
                showToast('请输入模板名称');
                return;
            }
            
            // 收集任务
            const taskItems = document.querySelectorAll('.template-task-item');
            const tasks = [];
            
            taskItems.forEach(item => {
                const taskName = item.querySelector('.template-task-name').value.trim();
                const taskTime = item.querySelector('.template-task-time').value;
                const taskIcon = item.querySelector('.template-task-icon').value;
                
                if (taskName) {
                    tasks.push({
                        name: taskName,
                        time: taskTime || '09:00',
                        icon: taskIcon
                    });
                }
            });
            
            if (tasks.length === 0) {
                showToast('请至少添加一个任务');
                return;
            }
            
            // 保存模板
            const templateId = editingTemplateId || 'custom_' + Date.now();
            customTemplates[templateId] = {
                id: templateId,
                name: name,
                icon: icon,
                tasks: tasks
            };
            
            saveTemplates();
            renderTemplateManageList();
            closeTemplateModal();
            showToast(editingTemplateId ? '模板已更新' : '模板已创建');
        }
        
        function deleteTemplate(templateId) {
            if (!confirm('确定要删除这个模板吗？')) return;
            
            delete customTemplates[templateId];
            saveTemplates();
            renderTemplateManageList();
            showToast('模板已删除');
        }
        
        function closeTemplateModal(e) {
            if (!e || e.target.id === 'template-modal') {
                document.getElementById('template-modal').classList.remove('show');
            }
        }
        
        // ========== 帮助功能 ==========
        // 获取帮助提示存储key
        function getHelpKey() {
            return getUserStorageKey('schedule-help-shown');
        }
        
        function checkAndShowHelp() {
            // 使用新的设置系统检查是否显示帮助
            if (appSettings.showHelpOnStart !== false) {
                setTimeout(() => {
                    openHelpModal();
                }, 500); // 延迟半秒显示，让页面先加载完成
            }
        }
        
        function openHelpModal() {
            document.getElementById('help-modal').classList.add('show');
            // 恢复复选框状态
            document.getElementById('help-dont-show').checked = appSettings.showHelpOnStart === false;
        }
        
        function closeHelpModal(e) {
            if (!e || e.target.id === 'help-modal') {
                document.getElementById('help-modal').classList.remove('show');
            }
        }
        
        function toggleHelpSetting() {
            const checkbox = document.getElementById('help-dont-show');
            appSettings.showHelpOnStart = !checkbox.checked;
            localStorage.setItem(getSettingsKey(), JSON.stringify(appSettings));
        }
        
        // 导出帮助弹窗
        function openExportHelpModal() {
            document.getElementById('export-help-modal').classList.add('show');
        }
        
        function closeExportHelpModal(e) {
            if (!e || e.target.id === 'export-help-modal') {
                document.getElementById('export-help-modal').classList.remove('show');
            }
        }
        
        function getTasks() {
            const data = localStorage.getItem(getTasksKey());
            return data ? JSON.parse(data) : [];
        }
        
        function saveTasks() {
            localStorage.setItem(getTasksKey(), JSON.stringify(tasks));
        }
        
        function getTasksForDate(date) {
            const dateStr = new Date(date).toDateString();
            return tasks.filter(t => new Date(t.date).toDateString() === dateStr);
        }
        
        function setupDefaultTime() {
            const now = new Date();
            now.setHours(now.getHours() + 1);
            now.setMinutes(0);
            const timeStr = `${String(now.getHours()).padStart(2, '0')}:00`;
            document.getElementById('add-time').value = timeStr;
            // 同步更新开始时间字段
            document.getElementById('add-start-time').value = timeStr;
            document.getElementById('start-time-text').textContent = timeStr;
            document.getElementById('add-date').value = currentDate.toISOString().split('T')[0];
        }
        
        // ========== 天气功能 ==========
        async function getWeather(lat, lon, cityName) {
            const card = document.getElementById('weather-card');
            
            // 离线时直接显示离线提示
            if (!navigator.onLine) {
                card.innerHTML = `
                    <div class="weather-offline">
                        <div style="font-size: 24px; margin-bottom: 8px;">📡</div>
                        <div>当前处于离线模式</div>
                        <div style="font-size: 12px; opacity: 0.7; margin-top: 4px;">天气信息暂不可用</div>
                    </div>
                `;
                return;
            }
            
            card.innerHTML = '<div class="weather-loading">正在获取天气...</div>';
            
            try {
                // 使用 Open-Meteo API (免费，无需key)
                const response = await fetch(
                    `https://api.open-meteo.com/v1/forecast?latitude=${lat}&longitude=${lon}&current_weather=true&daily=temperature_2m_max,temperature_2m_min&timezone=auto`
                );
                
                if (!response.ok) throw new Error('获取失败');
                
                const data = await response.json();
                const current = data.current_weather;
                const daily = data.daily;
                
                const icon = WEATHER_ICONS[current.weathercode] || '🌡️';
                const desc = WEATHER_DESC[current.weathercode] || '未知';
                const maxTemp = Math.round(daily.temperature_2m_max[0]);
                const minTemp = Math.round(daily.temperature_2m_min[0]);
                
                card.innerHTML = `
                    <div class="weather-location" onclick="openCityModal()">
                        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"></path>
                            <circle cx="12" cy="10" r="3"></circle>
                        </svg>
                        ${cityName}
                    </div>
                    <div class="weather-main">
                        <div class="weather-temp">${Math.round(current.temperature)}<span>°C</span></div>
                        <div class="weather-info">
                            <div class="weather-icon">${icon}</div>
                            <div class="weather-desc">${desc}</div>
                        </div>
                    </div>
                    <div class="weather-details">
                        <div class="weather-detail">
                            <span>↑</span> ${maxTemp}°
                        </div>
                        <div class="weather-detail">
                            <span>↓</span> ${minTemp}°
                        </div>
                        <div class="weather-detail">
                            <span>↗</span> ${current.windspeed}km/h
                        </div>
                    </div>
                `;
                
                // 保存城市
                currentCity = { name: cityName, lat, lon };
                localStorage.setItem(WEATHER_KEY, JSON.stringify(currentCity));
                
            } catch (error) {
                card.innerHTML = `
                    <div class="weather-error">
                        获取天气失败<br>
                        <button onclick="openCityModal()">手动选择城市</button>
                    </div>
                `;
            }
        }
        
        function locateAndGetWeather() {
            const card = document.getElementById('weather-card');
            
            // 离线时跳过定位
            if (!navigator.onLine) {
                card.innerHTML = `
                    <div class="weather-offline">
                        <div style="font-size: 24px; margin-bottom: 8px;">📡</div>
                        <div>当前处于离线模式</div>
                        <div style="font-size: 12px; opacity: 0.7; margin-top: 4px;">天气信息暂不可用</div>
                    </div>
                `;
                return;
            }
            
            card.innerHTML = '<div class="weather-loading">正在定位...</div>';
            
            if (!navigator.geolocation) {
                showToast('浏览器不支持定位');
                openCityModal();
                return;
            }
            
            navigator.geolocation.getCurrentPosition(
                async (position) => {
                    const { latitude, longitude } = position.coords;
                    // 使用反向地理编码获取城市名（简化处理）
                    await getWeather(latitude, longitude, '当前位置');
                },
                (error) => {
                    console.error('定位失败:', error);
                    showToast('定位失败，请手动选择城市');
                    openCityModal();
                },
                { timeout: 10000, enableHighAccuracy: false }
            );
        }
        
        // ========== 城市选择 ==========
        function openCityModal() {
            document.getElementById('city-modal').classList.add('show');
            document.getElementById('city-search').value = '';
            renderCityList(CITIES);
        }
        
        function closeCityModal(e) {
            if (!e || e.target.id === 'city-modal') {
                document.getElementById('city-modal').classList.remove('show');
            }
        }
        
        function renderCityList(cities) {
            const list = document.getElementById('city-list');
            list.innerHTML = cities.map(city => `
                <div class="city-item ${currentCity?.name === city.name ? 'selected' : ''}" onclick="selectCity('${city.name}', ${city.lat}, ${city.lon})">
                    <span class="city-name">${city.name}</span>
                </div>
            `).join('');
        }
        
        function searchCity() {
            const query = document.getElementById('city-search').value.trim().toLowerCase();
            if (!query) {
                renderCityList(CITIES);
                return;
            }
            
            const filtered = CITIES.filter(c => c.name.toLowerCase().includes(query));
            renderCityList(filtered);
        }
        
        function selectCity(name, lat, lon) {
            getWeather(lat, lon, name);
            closeCityModal();
            showToast(`已切换到 ${name}`);
        }
        
        // ========== 日程功能 ==========
        function renderAll() {
            updateHeader();
            renderMiniCalendar();
            renderQuickDates();
            renderStats();
            renderDayView();
            renderWeekView();
            renderMonthView();
            renderListView();
            renderTodayView();  // 渲染今日计划视图
            loadDiaryForCurrentDate();  // 加载当前日期的日记
        }
        
        function updateHeader() {
            const weekdays = ['星期日', '星期一', '星期二', '星期三', '星期四', '星期五', '星期六'];
            document.getElementById('header-date').textContent = 
                `${currentDate.getFullYear()}年${currentDate.getMonth() + 1}月${currentDate.getDate()}日`;
            document.getElementById('header-weekday').textContent = weekdays[currentDate.getDay()];
        }
        
        function renderMiniCalendar() {
            const year = sideCalMonth.getFullYear();
            const month = sideCalMonth.getMonth();
            
            document.getElementById('year-display').textContent = year;
            document.getElementById('side-cal-month').textContent = `${month + 1}月`;
            
            const firstDay = new Date(year, month, 1).getDay();
            const daysInMonth = new Date(year, month + 1, 0).getDate();
            const daysInPrevMonth = new Date(year, month, 0).getDate();
            
            // 星期标题，周一为第一天
            const dayNames = ['一', '二', '三', '四', '五', '六', '日'];
            let html = dayNames.map(d => `<div class="side-cal-day">${d}</div>`).join('');
            
            // 调整 firstDay：getDay() 返回 0=周日, 1=周一... 我们要让周一为第一天
            const adjustedFirstDay = firstDay === 0 ? 6 : firstDay - 1;
            
            // 上月
            for (let i = adjustedFirstDay - 1; i >= 0; i--) {
                html += `<div class="side-cal-date" style="color: var(--text-muted); background: var(--bg-secondary);">${daysInPrevMonth - i}</div>`;
            }
            
            // 本月
            const today = new Date();
            for (let i = 1; i <= daysInMonth; i++) {
                const date = new Date(year, month, i);
                const isToday = date.toDateString() === today.toDateString();
                const isSelected = date.toDateString() === currentDate.toDateString();
                const hasTasks = getTasksForDate(date).length > 0;
                
                // 判断是否是周末
                const dayOfWeek = date.getDay();
                const isWeekend = dayOfWeek === 0 || dayOfWeek === 6;
                
                html += `<div class="side-cal-date ${isToday ? 'today' : ''} ${isSelected ? 'selected' : ''} ${hasTasks ? 'has-tasks' : ''} ${isWeekend ? 'weekend' : ''}" 
                          onclick="selectDate(${year}, ${month}, ${i})">${i}</div>`;
            }
            
            // 下月
            const totalCells = adjustedFirstDay + daysInMonth;
            const remaining = (42 - totalCells) % 42;
            for (let i = 1; i <= remaining; i++) {
                html += `<div class="side-cal-date" style="color: var(--text-muted); background: var(--bg-secondary);">${i}</div>`;
            }
            
            document.getElementById('side-cal-grid').innerHTML = html;
        }
        
        function changeSideMonth(delta) {
            sideCalMonth.setMonth(sideCalMonth.getMonth() + delta);
            renderMiniCalendar();
        }
        
        function goToToday() {
            currentDate = new Date();
            currentMonth = new Date();
            sideCalMonth = new Date();
            renderAll();
        }
        
        function selectDate(year, month, day) {
            currentDate = new Date(year, month, day);
            renderAll();
            if (currentView === 'month') {
                switchView('day');
            }
        }
        
        // ========== 快捷日期折叠功能 ==========
        // 获取UI状态存储key
        function getQuickDatesCollapsedKey() {
            return getUserStorageKey('schedule-quick-dates-collapsed');
        }
        
        function getSidebarCalendarCollapsedKey() {
            return getUserStorageKey('schedule-sidebar-calendar-collapsed');
        }
        
        function initQuickDatesState() {
            const isCollapsed = localStorage.getItem(getQuickDatesCollapsedKey()) === 'true';
            const container = document.getElementById('quick-dates');
            if (isCollapsed) {
                container.classList.add('collapsed');
            }
        }
        
        function toggleQuickDates() {
            const container = document.getElementById('quick-dates');
            const isCollapsed = container.classList.toggle('collapsed');
            localStorage.setItem(getQuickDatesCollapsedKey(), isCollapsed);
        }
        
        function initSidebarCalendarState() {
            const isCollapsed = localStorage.getItem(getSidebarCalendarCollapsedKey()) === 'true';
            const container = document.getElementById('sidebar-calendar');
            if (isCollapsed) {
                container.classList.add('collapsed');
            }
        }
        
        function toggleSidebarCalendar() {
            const container = document.getElementById('sidebar-calendar');
            const isCollapsed = container.classList.toggle('collapsed');
            localStorage.setItem(getSidebarCalendarCollapsedKey(), isCollapsed);
        }

        function searchTasks() {
            const searchTerm = document.getElementById('task-search').value.toLowerCase().trim();
            
            // 如果搜索框为空，显示所有任务
            if (!searchTerm) {
                renderAll();
                return;
            }
            
            // 过滤任务
            const filteredTasks = tasks.filter(task => {
                return task.name.toLowerCase().includes(searchTerm) ||
                       task.time.toLowerCase().includes(searchTerm) ||
                       (task.icon && task.icon.toLowerCase().includes(searchTerm));
            });
            
            // 重新渲染任务列表
            if (currentView === 'list') {
                renderListView(filteredTasks);
            } else {
                // 对于其他视图，我们可以在当前日期的任务中过滤
                const currentDateTasks = getTasksForDate(currentDate);
                const filteredCurrentTasks = currentDateTasks.filter(task => {
                    return task.name.toLowerCase().includes(searchTerm) ||
                           task.time.toLowerCase().includes(searchTerm) ||
                           (task.icon && task.icon.toLowerCase().includes(searchTerm));
                });
                renderAll();
            }
        }
        
        function renderQuickDates() {
            const days = ['今天', '明天', '后天'];
            const today = new Date();
            
            let html = '';
            for (let i = 0; i < 3; i++) {
                const date = new Date(today);
                date.setDate(today.getDate() + i);
                const isActive = date.toDateString() === currentDate.toDateString();
                const count = getTasksForDate(date).length;
                
                html += `
                    <div class="quick-date-item ${isActive ? 'active' : ''}" onclick="selectDate(${date.getFullYear()}, ${date.getMonth()}, ${date.getDate()})">
                        <span class="quick-date-day">${days[i]}</span>
                        <span class="quick-date-num">${date.getMonth() + 1}/${date.getDate()}</span>
                        ${count > 0 ? `<span class="quick-date-count">${count}</span>` : ''}
                    </div>
                `;
            }
            
            document.getElementById('quick-dates-list').innerHTML = html;
        }
        
        function renderStats() {
            const dayTasks = getTasksForDate(currentDate);
            const total = dayTasks.length;
            const done = dayTasks.filter(t => t.completed).length;
            const percent = total > 0 ? Math.round((done / total) * 100) : 0;
            
            document.getElementById('stat-total').textContent = total;
            document.getElementById('stat-done').textContent = done;
            document.getElementById('stat-progress').style.width = percent + '%';
        }
        
        // 周视图当前日期
        let currentWeekDate = new Date();
        
        // 星期名称，周一为第一天
        const DAY_NAMES = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
        
        function switchView(view) {
            currentView = view;
            
            document.querySelectorAll('.view-tab').forEach(t => t.classList.remove('active'));
            document.getElementById(`tab-${view}`).classList.add('active');
            
            ['day', 'week', 'month', 'list', 'today'].forEach(v => {
                const el = document.getElementById(`view-${v}`);
                if (el) el.classList.toggle('hidden', v !== view);
            });
            
            renderAll();
        }
        
        // 获取周开始日期（周一）
        function isSameDay(date1, date2) {
            const d1 = new Date(date1);
            const d2 = new Date(date2);
            return d1.getFullYear() === d2.getFullYear() &&
                   d1.getMonth() === d2.getMonth() &&
                   d1.getDate() === d2.getDate();
        }

        function getWeekStart(date) {
            const d = new Date(date);
            const day = d.getDay(); // 0=周日, 1=周一, ..., 6=周六
            
            // 根据设置决定周开始是周一还是周日
            const startOnMonday = appSettings.weekStart === 'monday';
            
            if (startOnMonday) {
                // 周一为第一天：如果今天是周日(0)，则返回上周一；否则返回本周一
                const diff = d.getDate() - day + (day === 0 ? -6 : 1);
                return new Date(d.setDate(diff));
            } else {
                // 周日为第一天：返回本周日
                const diff = d.getDate() - day;
                return new Date(d.setDate(diff));
            }
        }
        
        // 切换周
        function changeWeek(delta) {
            currentWeekDate.setDate(currentWeekDate.getDate() + delta * 7);
            renderWeekView();
        }
        
        // 回到当前周
        function goToCurrentWeek() {
            currentWeekDate = new Date();
            renderWeekView();
        }
        
        // 渲染周视图
        function renderWeekView() {
            const weekStart = getWeekStart(currentWeekDate);
            const weekGrid = document.getElementById('week-grid');
            const weekTitle = document.getElementById('week-title');
            const today = new Date();
            
            // 更新标题
            const weekEnd = new Date(weekStart);
            weekEnd.setDate(weekEnd.getDate() + 6);
            const monthStr = weekStart.getMonth() + 1;
            weekTitle.textContent = `${weekStart.getFullYear()}年 ${monthStr}月 第${getWeekNumber(weekStart)}周`;
            
            weekGrid.innerHTML = '';
            
            for (let i = 0; i < 7; i++) {
                const dayDate = new Date(weekStart);
                dayDate.setDate(dayDate.getDate() + i);
                
                const isToday = isSameDay(dayDate, today);
                // 周一为第一天，所以周末是索引5(周六)和6(周日)
                const isWeekend = i === 5 || i === 6;
                const dayTasks = getTasksForDate(dayDate);
                
                const column = document.createElement('div');
                column.className = `week-day-column ${isToday ? 'today' : ''} ${isWeekend ? 'weekend' : ''}`;
                
                column.innerHTML = `
                    <div class="week-day-header">
                        <div class="week-day-name">${DAY_NAMES[i]}</div>
                        <div class="week-day-number">${dayDate.getDate()}</div>
                    </div>
                    <div class="week-day-tasks">
                        ${dayTasks.length === 0 ? 
                            '<p style="text-align: center; color: var(--text-muted); font-size: 12px; padding: 20px 0;">暂无任务</p>' :
                            dayTasks.sort((a, b) => a.time.localeCompare(b.time)).map(task => {
                                const timeDisplay = task.endTime ? `${task.time}-${task.endTime}` : task.time;
                                return `
                                <div class="week-task-item ${task.completed ? 'done' : ''} ${task.endTime ? 'has-range' : ''}" data-id="${task.id}" onclick="handleWeekTaskClick('${task.id}', event)">
                                    <div class="week-task-time">${timeDisplay}</div>
                                    <div class="week-task-name">
                                        <span>${task.icon || '•'}</span>
                                        <span>${escapeHtml(task.name)}${task.rewardType ? `<span class="task-reward-badge" style="font-size: 10px; padding: 2px 4px; margin-left: 4px;">${task.rewardType === 'audio' ? '🎤' : '🎬'}</span>` : ''}</span>
                                    </div>
                                </div>
                            `}).join('')
                        }
                    </div>
                    <button class="week-add-btn" onclick="openAddPanelForDate('${dayDate.toISOString()}')">+ 添加</button>
                `;
                
                weekGrid.appendChild(column);
            }
        }
        
        // 获取周数
        function getWeekNumber(date) {
            const d = new Date(Date.UTC(date.getFullYear(), date.getMonth(), date.getDate()));
            const dayNum = d.getUTCDay() || 7;
            d.setUTCDate(d.getUTCDate() + 4 - dayNum);
            const yearStart = new Date(Date.UTC(d.getUTCFullYear(), 0, 1));
            return Math.ceil((((d - yearStart) / 86400000) + 1) / 7);
        }
        
        // 周视图任务点击处理
        function handleWeekTaskClick(taskId, event) {
            event.stopPropagation();
            toggleTask(taskId);
        }
        
        // 为指定日期打开添加面板
        function openAddPanelForDate(dateStr) {
            const date = new Date(dateStr);
            currentDate = date;
            
            // 更新日期显示
            const dateInput = document.getElementById('add-date');
            const dateDisplay = document.getElementById('date-display-text');
            const dateValue = date.toISOString().split('T')[0];
            
            dateInput.value = dateValue;
            dateDisplay.textContent = `${date.getMonth() + 1}月${date.getDate()}日`;
            
            openAddPanel();
        }
        
        function renderDayView() {
            const dayTasks = getTasksForDate(currentDate);
            const container = document.getElementById('day-slots');
            const empty = document.getElementById('day-empty');
            
            if (dayTasks.length === 0) {
                container.innerHTML = '';
                empty.classList.remove('hidden');
                return;
            }
            
            empty.classList.add('hidden');
            
            const hourTasks = {};
            dayTasks.forEach(t => {
                const hour = parseInt(t.time.split(':')[0]);
                if (!hourTasks[hour]) hourTasks[hour] = [];
                hourTasks[hour].push(t);
            });
            
            const now = new Date();
            const currentHour = now.getHours();
            
            let html = '';
            for (let hour = 6; hour <= 23; hour++) {
                const tasksInHour = hourTasks[hour] || [];
                const hasTask = tasksInHour.length > 0;
                const isCurrent = hour === currentHour;
                
                html += `
                    <div class="time-slot ${hasTask ? 'has-task' : ''}">
                        <div class="time-label">${String(hour).padStart(2, '0')}:00</div>
                        <div class="time-content">
                            ${tasksInHour.map(t => {
                                const member = t.memberId ? getMemberById(t.memberId) : null;
                                const memberIndicator = member ? `
                                    <div class="task-member-indicator">
                                        <div class="task-member-dot" style="background: ${member.color};"></div>
                                        <span class="task-member-name">${escapeHtml(member.name)}</span>
                                    </div>
                                ` : '';
                                const imageHtml = t.image ? `
                                    <img src="${t.image}" style="width: 40px; height: 40px; object-fit: cover; border-radius: 6px; margin-right: 8px;">
                                ` : '';
                                const rewardBadge = t.rewardType ? `<span class="task-reward-badge" title="完成任务有奖励">${t.rewardType === 'audio' ? '🎤' : '🎬'}</span>` : '';
                                const timeDisplay = t.endTime ? `${t.time}-${t.endTime}` : t.time;
                                return `
                                <div class="time-slot-task ${t.completed ? 'done' : ''} ${isCurrent && !t.completed ? 'current' : ''} ${t.endTime ? 'has-range' : ''}" 
                                     data-id="${t.id}"
                                     style="${member ? `border-left: 4px solid ${member.color};` : ''}">
                                    <div style="display: flex; align-items: center; gap: 8px; cursor: pointer;" onclick="toggleTask('${t.id}')">
                                        ${t.icon || ''}
                                        ${imageHtml}
                                        <span>${escapeHtml(t.name)}${rewardBadge}</span>
                                        <span style="color: var(--text-muted); font-size: 13px; margin-left: auto;">${timeDisplay}</span>
                                    </div>
                                    ${memberIndicator}
                                    <div class="task-actions">
                                        <button class="edit" onclick="editTask('${t.id}', event)" title="编辑">
                                            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                                <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path>
                                                <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path>
                                            </svg>
                                        </button>
                                        <button class="delete" onclick="deleteTask('${t.id}', event)" title="删除">
                                            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                                <polyline points="3 6 5 6 21 6"></polyline>
                                                <path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"></path>
                                            </svg>
                                        </button>
                                    </div>
                                </div>
                            `;}).join('')}
                        </div>
                    </div>
                `;
            }
            
            container.innerHTML = html;
        }
        
        function renderMonthView() {
            const year = currentMonth.getFullYear();
            const month = currentMonth.getMonth();
            
            document.getElementById('month-title').textContent = `${year}年${month + 1}月`;
            
            const firstDay = new Date(year, month, 1).getDay();
            const daysInMonth = new Date(year, month + 1, 0).getDate();
            const daysInPrevMonth = new Date(year, month, 0).getDate();
            
            // 星期标题，周一为第一天
            const weekdays = ['一', '二', '三', '四', '五', '六', '日'];
            let html = weekdays.map(d => `<div class="month-weekday">${d}</div>`).join('');
            
            // 调整 firstDay：getDay() 返回 0=周日, 1=周一... 我们要让周一为第一天
            // 所以原来的周日(0)应该变成6，周一(1)变成0，以此类推
            const adjustedFirstDay = firstDay === 0 ? 6 : firstDay - 1;
            
            // 上月
            for (let i = adjustedFirstDay - 1; i >= 0; i--) {
                html += `<div class="month-day other-month"><div class="month-day-num">${daysInPrevMonth - i}</div></div>`;
            }
            
            // 本月
            const today = new Date();
            for (let i = 1; i <= daysInMonth; i++) {
                const date = new Date(year, month, i);
                const isToday = date.toDateString() === today.toDateString();
                const isSelected = date.toDateString() === currentDate.toDateString();
                const dayTasks = getTasksForDate(date);
                
                // 判断是否是周末 (getDay(): 0=周日, 6=周六)
                const dayOfWeek = date.getDay();
                const isWeekend = dayOfWeek === 0 || dayOfWeek === 6;
                
                html += `
                    <div class="month-day ${isToday ? 'today' : ''} ${isSelected ? 'selected' : ''} ${isWeekend ? 'weekend' : ''}" 
                         onclick="selectDate(${year}, ${month}, ${i})">
                        <div class="month-day-num">${i}</div>
                        <div class="month-day-tasks">
                            ${dayTasks.slice(0, 3).map(t => {
                                const member = t.memberId ? getMemberById(t.memberId) : null;
                                return `
                                <div class="month-task-item" style="${member ? `color: ${member.color}; font-weight: 500;` : ''}">
                                    ${t.icon || '•'} ${escapeHtml(t.name)}
                                </div>
                            `;}).join('')}
                            ${dayTasks.length > 3 ? `<div class="month-task-item">+${dayTasks.length - 3} 更多</div>` : ''}
                        </div>
                    </div>
                `;
            }
            
            // 下月
            const totalCells = adjustedFirstDay + daysInMonth;
            const remaining = (7 - (totalCells % 7)) % 7;
            for (let i = 1; i <= remaining; i++) {
                html += `<div class="month-day other-month"><div class="month-day-num">${i}</div></div>`;
            }
            
            document.getElementById('month-grid').innerHTML = html;
        }
        
        function changeMonth(delta) {
            currentMonth.setMonth(currentMonth.getMonth() + delta);
            renderMonthView();
        }
        
        function renderListView(filteredTasks) {
            const dayTasks = filteredTasks || getTasksForDate(currentDate);
            const container = document.getElementById('list-tasks');
            const empty = document.getElementById('list-empty');
            
            if (dayTasks.length === 0) {
                container.innerHTML = '';
                empty.classList.remove('hidden');
                return;
            }
            
            empty.classList.add('hidden');
            
            const sorted = [...dayTasks].sort((a, b) => a.time.localeCompare(b.time));
            const now = new Date();
            const currentTime = `${String(now.getHours()).padStart(2, '0')}:${String(now.getMinutes()).padStart(2, '0')}`;
            let activeFound = false;
            
            container.innerHTML = sorted.map(t => {
                const isActive = !t.completed && !activeFound && t.time >= currentTime;
                if (isActive) activeFound = true;
                
                const member = t.memberId ? getMemberById(t.memberId) : null;
                const memberIndicator = member ? `
                    <div class="task-member-indicator" style="margin-top: 4px;">
                        <div class="task-member-dot" style="background: ${member.color};"></div>
                        <span class="task-member-name">${escapeHtml(member.name)}</span>
                    </div>
                ` : '';
                
                const imageHtml = t.image ? `
                    <img src="${t.image}" style="width: 50px; height: 50px; object-fit: cover; border-radius: 8px; margin-right: 12px; flex-shrink: 0;">
                ` : '';
                
                const timeDisplay = t.endTime ? `${t.time} - ${t.endTime}` : t.time;
                const isSelected = selectedTaskIds.has(t.id);
                
                // 批量删除模式下的任务项
                if (isBatchDeleteMode) {
                    return `
                        <div class="task-item batch-mode ${isSelected ? 'batch-selected' : ''} ${t.completed ? 'done' : ''} ${isActive ? 'current' : ''} ${t.endTime ? 'has-range' : ''}" 
                             data-id="${t.id}"
                             onclick="toggleTaskSelection('${t.id}')"
                             style="${member ? `border-left: 4px solid ${member.color};` : ''}">
                            <div class="batch-checkbox ${isSelected ? 'selected' : ''}"></div>
                            ${imageHtml}
                            <div class="task-info">
                                <div class="task-name">${t.icon ? t.icon + ' ' : ''}${escapeHtml(t.name)}${t.rewardType ? `<span class="task-reward-badge">${t.rewardType === 'audio' ? '🎤' : '🎬'}</span>` : ''}</div>
                                <div class="task-time">${timeDisplay}</div>
                                ${memberIndicator}
                            </div>
                        </div>
                    `;
                }
                
                // 普通模式下的任务项
                return `
                    <div class="task-item ${t.completed ? 'done' : ''} ${isActive ? 'current' : ''} ${t.endTime ? 'has-range' : ''}" 
                         data-id="${t.id}"
                         style="${member ? `border-left: 4px solid ${member.color};` : ''}">
                        <div class="checkbox" onclick="toggleTask('${t.id}', event)"></div>
                        ${imageHtml}
                        <div class="task-info">
                            <div class="task-name">${t.icon ? t.icon + ' ' : ''}${escapeHtml(t.name)}${t.rewardType ? `<span class="task-reward-badge">${t.rewardType === 'audio' ? '🎤' : '🎬'}</span>` : ''}</div>
                            <div class="task-time">${timeDisplay}</div>
                            ${memberIndicator}
                        </div>
                        <div class="task-actions">
                            <button class="task-edit" onclick="editTask('${t.id}', event)">
                                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                    <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path>
                                    <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path>
                                </svg>
                            </button>
                            <button class="task-delete ${pendingDeleteId === t.id ? 'task-delete-confirm' : ''}" onclick="deleteTask('${t.id}', event)" title="${pendingDeleteId === t.id ? '点击确认删除' : '删除'}">
                                ${pendingDeleteId === t.id ? `
                                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                        <polyline points="20 6 9 17 4 12"></polyline>
                                    </svg>
                                ` : `
                                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                        <polyline points="3 6 5 6 21 6"></polyline>
                                        <path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"></path>
                                    </svg>
                                `}
                            </button>
                        </div>
                    </div>
                `;
            }).join('');
        }
        
        // ========== 今日计划视图（动态流式） ==========
        
        function renderTodayView() {
            const dayTasks = getTasksForDate(currentDate);
            const container = document.getElementById('today-timeline');
            const empty = document.getElementById('today-empty');
            const header = document.getElementById('today-header');
            
            // 更新头部信息
            updateTodayHeader();
            
            // 更新进度
            updateTodayProgress(dayTasks);
            
            if (dayTasks.length === 0) {
                container.innerHTML = '';
                empty.classList.remove('hidden');
                return;
            }
            
            empty.classList.add('hidden');
            
            // 按时间排序
            const sorted = [...dayTasks].sort((a, b) => a.time.localeCompare(b.time));
            
            // 找出当前任务
            const now = new Date();
            const currentTime = `${String(now.getHours()).padStart(2, '0')}:${String(now.getMinutes()).padStart(2, '0')}`;
            let activeFound = false;
            
            container.innerHTML = sorted.map((t, index) => {
                const isActive = !t.completed && !activeFound && t.time >= currentTime;
                if (isActive) activeFound = true;
                
                const isCompleted = t.completed;
                const statusClass = isCompleted ? 'completed' : (isActive ? 'current' : '');
                
                // 解析时间
                const [hour, minute] = t.time.split(':');
                const hourNum = parseInt(hour);
                const period = hourNum < 12 ? '上午' : (hourNum < 18 ? '下午' : '晚上');
                const displayHour = hourNum <= 12 ? hourNum : hourNum - 12;
                
                // 状态标签
                let statusText = '待完成';
                let statusClassName = 'pending';
                if (isCompleted) {
                    statusText = '已完成';
                    statusClassName = 'completed';
                } else if (isActive) {
                    statusText = '进行中';
                    statusClassName = 'current';
                }
                
                // 持续时间
                let durationText = '';
                if (t.endTime) {
                    durationText = `<span>⏱️ ${t.time} - ${t.endTime}</span>`;
                } else {
                    durationText = `<span>⏱️ 约30分钟</span>`;
                }
                
                // 成员信息
                const member = t.memberId ? getMemberById(t.memberId) : null;
                const memberHtml = member ? `
                    <div style="display: flex; align-items: center; gap: 6px; margin-top: 8px;">
                        <div style="width: 8px; height: 8px; border-radius: 50%; background: ${member.color};"></div>
                        <span style="font-size: 12px; color: var(--text-muted);">${escapeHtml(member.name)}</span>
                    </div>
                ` : '';
                
                // 奖励标识
                const rewardHtml = t.rewardType ? `
                    <span style="font-size: 12px; margin-left: 8px;">${t.rewardType === 'audio' ? '🎤' : '🎬'}</span>
                ` : '';
                
                return `
                    <div class="timeline-item ${statusClass}" data-id="${t.id}">
                        <div class="timeline-time">
                            <span class="time">${displayHour}:${minute}</span>
                            <span class="period">${period}</span>
                        </div>
                        <div class="timeline-dot"></div>
                        <div class="timeline-content">
                            <div class="timeline-header">
                                <span class="timeline-icon">${t.icon || '•'}</span>
                                <span class="timeline-title">${escapeHtml(t.name)}${rewardHtml}</span>
                                <span class="timeline-status ${statusClassName}">${statusText}</span>
                            </div>
                            <div class="timeline-duration">
                                ${durationText}
                                ${t.image ? '<span>📷 含图片</span>' : ''}
                            </div>
                            ${memberHtml}
                            <div class="timeline-actions">
                                ${!isCompleted ? `
                                    <button class="timeline-btn complete" onclick="completeTodayTask('${t.id}')">
                                        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                            <polyline points="20 6 9 17 4 12"></polyline>
                                        </svg>
                                        完成
                                    </button>
                                ` : `
                                    <button class="timeline-btn" onclick="undoTodayTask('${t.id}')">
                                        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                            <path d="M3 7v6h6"></path>
                                            <path d="M21 17a9 9 0 0 0-9-9 9 9 0 0 0-6 2.3L3 13"></path>
                                        </svg>
                                        撤销
                                    </button>
                                `}
                                <button class="timeline-btn" onclick="editTask('${t.id}', event)">
                                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                        <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path>
                                        <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path>
                                    </svg>
                                    编辑
                                </button>
                            </div>
                        </div>
                    </div>
                `;
            }).join('');
        }
        
        // 更新今日计划头部信息
        function updateTodayHeader() {
            const weekdays = ['星期日', '星期一', '星期二', '星期三', '星期四', '星期五', '星期六'];
            const months = ['1月', '2月', '3月', '4月', '5月', '6月', '7月', '8月', '9月', '10月', '11月', '12月'];
            
            // 更新用户名和头像
            const usernameEl = document.getElementById('today-username');
            const avatarEl = document.getElementById('today-avatar');
            
            if (currentUser) {
                usernameEl.textContent = currentUser.childName || currentUser.username || '用户';
                if (currentUser.avatar) {
                    avatarEl.innerHTML = `<img src="${currentUser.avatar}" alt="头像">`;
                } else {
                    const name = currentUser.username || '?';
                    avatarEl.textContent = name.charAt(0).toUpperCase();
                }
            } else {
                usernameEl.textContent = '访客';
                avatarEl.textContent = '?';
            }
            
            // 更新日期
            document.getElementById('today-date').textContent = 
                `${months[currentDate.getMonth()]}${currentDate.getDate()}日 ${weekdays[currentDate.getDay()]}`;
            
            // 更新时间（实时更新）
            updateTodayTime();
        }
        
        // 更新当前时间
        function updateTodayTime() {
            const now = new Date();
            const timeStr = `${String(now.getHours()).padStart(2, '0')}:${String(now.getMinutes()).padStart(2, '0')}`;
            document.getElementById('today-time').textContent = timeStr;
        }
        
        // 每秒更新时间
        setInterval(() => {
            if (currentView === 'today') {
                updateTodayTime();
            }
        }, 1000);
        
        // 更新今日进度
        function updateTodayProgress(dayTasks) {
            const total = dayTasks.length;
            const completed = dayTasks.filter(t => t.completed).length;
            const percent = total > 0 ? Math.round((completed / total) * 100) : 0;
            
            document.getElementById('today-progress-percent').textContent = `${percent}%`;
            document.getElementById('today-progress-fill').style.width = `${percent}%`;
        }
        
        // 完成今日任务
        function completeTodayTask(id) {
            toggleTask(id);
            // 添加完成动画效果
            const item = document.querySelector(`.timeline-item[data-id="${id}"]`);
            if (item) {
                item.style.animation = 'taskComplete 0.5s ease';
                setTimeout(() => {
                    item.style.animation = '';
                }, 500);
            }
        }
        
        // 撤销今日任务完成状态
        function undoTodayTask(id) {
            toggleTask(id);
        }
        
        // 完成动画
        const style = document.createElement('style');
        style.textContent = `
            @keyframes taskComplete {
                0% { transform: scale(1); }
                50% { transform: scale(1.02); background: rgba(16, 185, 129, 0.1); }
                100% { transform: scale(1); }
            }
        `;
        document.head.appendChild(style);
        
        function escape(text) {
            const div = document.createElement('div');
            div.textContent = text;
            return div.innerHTML;
        }
        
        // ========== 日记功能 ==========
        
        // 加载所有日记
        function loadDiaries() {
            try {
                const saved = localStorage.getItem(getDiaryStorageKey());
                if (saved) {
                    diaries = JSON.parse(saved);
                } else {
                    diaries = {};
                }
            } catch (e) {
                console.error('加载日记失败:', e);
                diaries = {};
            }
        }
        
        // 保存日记
        function saveDiaries() {
            try {
                localStorage.setItem(getDiaryStorageKey(), JSON.stringify(diaries));
            } catch (e) {
                console.error('保存日记失败:', e);
            }
        }
        
        // 获取当前日期的日记
        function getDiaryKey(date) {
            return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')}`;
        }
        
        // 加载当前日期的日记到界面
        function loadDiaryForCurrentDate() {
            const key = getDiaryKey(currentDate);
            const content = diaries[key] || '';
            const textarea = document.getElementById('diary-textarea');
            const statusEl = document.getElementById('diary-status');
            const dateEl = document.getElementById('diary-date');
            
            if (textarea) textarea.value = content;
            if (statusEl) {
                if (content.trim()) {
                    statusEl.textContent = '已记录';
                    statusEl.classList.add('recorded');
                } else {
                    statusEl.textContent = '未记录';
                    statusEl.classList.remove('recorded');
                }
            }
            if (dateEl) {
                dateEl.textContent = currentDate.toLocaleDateString('zh-CN', { 
                    year: 'numeric', month: 'long', day: 'numeric', weekday: 'long' 
                });
            }
        }
        
        // 展开/折叠日记区域
        function toggleDiary() {
            const section = document.getElementById('diary-section');
            section.classList.toggle('expanded');
        }
        
        // 保存日记
        function saveDiary() {
            const textarea = document.getElementById('diary-textarea');
            const content = textarea.value.trim();
            const key = getDiaryKey(currentDate);
            
            if (content) {
                diaries[key] = content;
                saveDiaries();
                showToast('日记已保存');
            } else {
                delete diaries[key];
                saveDiaries();
                showToast('日记已清空');
            }
            
            loadDiaryForCurrentDate();  // 刷新状态
        }
        
        // 清空日记
        function clearDiary() {
            const textarea = document.getElementById('diary-textarea');
            if (textarea.value.trim() && confirm('确定要清空今天的日记吗？')) {
                textarea.value = '';
                saveDiary();
            }
        }
        
        // 初始化时加载日记
        loadDiaries();
        
        // ========== 任务操作 ==========
        
        function toggleTask(id) {
            const task = tasks.find(t => t.id === id);
            if (task) {
                task.completed = !task.completed;
                saveTasks();
                renderAll();
                
                if (task.completed) {
                    // 播放完成音效
                    playCompleteSound();
                    
                    // 检查是否有自定义奖励
                    if (task.rewardType && task.rewardData) {
                        // 显示自定义奖励弹窗
                        showTaskReward(task);
                    } else {
                        // 显示默认完成确认弹窗
                        showCompletionModal(task);
                    }
                    // 触发庆祝动画
                    createConfetti();
                } else {
                    showToast('任务已恢复');
                }
            }
        }
        
        // 播放完成音效（使用简单的 Audio API）
        function playCompleteSound() {
            // 检查是否开启音效
            if (appSettings.completeSound === false) {
                console.log('音效已关闭');
                return;
            }
            
            try {
                // 创建音频上下文
                const AudioContext = window.AudioContext || window.webkitAudioContext;
                if (!AudioContext) {
                    console.log('浏览器不支持 Web Audio API');
                    return;
                }
                
                const ctx = new AudioContext();
                const now = ctx.currentTime;
                
                console.log('🎵 播放完成音效...');
                
                // 演奏一个简单的成功音效: 嘞啰嘞~
                [523.25, 659.25, 783.99, 1046.50].forEach((freq, i) => {
                    const osc = ctx.createOscillator();
                    const gain = ctx.createGain();
                    
                    osc.connect(gain);
                    gain.connect(ctx.destination);
                    
                    osc.frequency.value = freq;
                    osc.type = 'sine';
                    
                    const t = now + i * 0.08;
                    gain.gain.setValueAtTime(0, t);
                    gain.gain.linearRampToValueAtTime(0.4, t + 0.01);
                    gain.gain.exponentialRampToValueAtTime(0.001, t + 0.25);
                    
                    osc.start(t);
                    osc.stop(t + 0.3);
                });
                
                // 0.5秒后关闭音频上下文
                setTimeout(() => ctx.close(), 500);
                
                console.log('✓ 音效播放成功');
            } catch (e) {
                console.log('音效播放失败:', e);
            }
        }
        
        // 鼓励语列表
        const ENCOURAGEMENTS = [
            '太棒了！你做得真好！',
            '真厉害！继续保持！',
            '做得好！为你骄傲！',
            '超级棒！你做到了！',
            '真不错！继续加油！',
            '完美！你是最棒的！',
            '出色！任务完成！',
            '好样的！你真能干！'
        ];
        
        // 显示完成确认弹窗
        function showCompletionModal(task) {
            const modal = document.getElementById('completion-modal');
            const taskNameEl = document.getElementById('completed-task-name');
            const encouragementEl = document.getElementById('completion-encouragement');
            
            // 设置任务名称
            taskNameEl.textContent = (task.icon || '') + ' ' + task.name;
            
            // 随机选择鼓励语
            const randomEncouragement = ENCOURAGEMENTS[Math.floor(Math.random() * ENCOURAGEMENTS.length)];
            encouragementEl.textContent = randomEncouragement;
            
            // 显示弹窗
            modal.classList.add('show');
            
            // 3秒后自动关闭
            setTimeout(() => {
                closeCompletionModal();
            }, 3000);
        }
        
        // 关闭完成确认弹窗
        function closeCompletionModal() {
            const modal = document.getElementById('completion-modal');
            modal.classList.remove('show');
        }
        
        // 创建 Confetti 庆祝动画
        function createConfetti() {
            const container = document.getElementById('confetti-container');
            const colors = ['#FF6B6B', '#4ECDC4', '#45B7D1', '#96CEB4', '#FFEAA7', '#DDA0DD', '#F7DC6F', '#98D8C8'];
            
            // 创建 50 个 confetti
            for (let i = 0; i < 50; i++) {
                setTimeout(() => {
                    const confetti = document.createElement('div');
                    confetti.className = 'confetti';
                    
                    // 随机颜色
                    confetti.style.backgroundColor = colors[Math.floor(Math.random() * colors.length)];
                    
                    // 随机位置
                    confetti.style.left = Math.random() * 100 + '%';
                    
                    // 随机大小
                    const size = Math.random() * 10 + 8;
                    confetti.style.width = size + 'px';
                    confetti.style.height = size + 'px';
                    
                    // 随机动画延迟和持续时间
                    confetti.style.animationDuration = (Math.random() * 2 + 2) + 's';
                    confetti.style.animationDelay = (Math.random() * 0.5) + 's';
                    
                    // 随机形状
                    const shapes = ['circle', 'square', 'triangle'];
                    const shape = shapes[Math.floor(Math.random() * shapes.length)];
                    if (shape === 'circle') {
                        confetti.style.borderRadius = '50%';
                    } else if (shape === 'triangle') {
                        confetti.style.width = '0';
                        confetti.style.height = '0';
                        confetti.style.backgroundColor = 'transparent';
                        confetti.style.borderLeft = size/2 + 'px solid transparent';
                        confetti.style.borderRight = size/2 + 'px solid transparent';
                        confetti.style.borderBottom = size + 'px solid ' + colors[Math.floor(Math.random() * colors.length)];
                    }
                    
                    container.appendChild(confetti);
                    
                    // 动画结束后移除
                    setTimeout(() => {
                        confetti.remove();
                    }, 4000);
                }, i * 30);
            }
        }
        
        function openAddPanel() {
            // 设置默认时间为当前时间
            setNowTime();
            // 设置默认日期为当前选中日期
            const year = currentDate.getFullYear();
            const month = String(currentDate.getMonth() + 1).padStart(2, '0');
            const day = String(currentDate.getDate()).padStart(2, '0');
            document.getElementById('add-date').value = `${year}-${month}-${day}`;
            document.getElementById('date-display-text').textContent = `${currentDate.getMonth() + 1}月${currentDate.getDate()}日`;
            // 重置图片上传
            resetTaskImage();
            // 重置奖励区域
            resetRewardSection();
            document.getElementById('add-panel-overlay').classList.add('show');
            document.getElementById('add-name').focus();
        }
        
        // ========== 图片任务功能 ==========
        function handleTaskImageUpload(event) {
            const file = event.target.files[0];
            if (!file) return;
            
            if (!file.type.startsWith('image/')) {
                showToast('请选择图片文件');
                return;
            }
            
            if (file.size > 5 * 1024 * 1024) {
                showToast('图片不能超过5MB');
                return;
            }
            
            const reader = new FileReader();
            reader.onload = function(e) {
                const imageData = e.target.result;
                document.getElementById('add-image').value = imageData;
                
                // 显示预览
                const preview = document.getElementById('task-image-preview');
                preview.src = imageData;
                preview.classList.remove('hidden');
                
                // 隐藏占位符
                document.querySelector('.image-upload-placeholder').style.display = 'none';
                
                // 显示删除按钮
                document.querySelector('.image-remove-btn').classList.remove('hidden');
            };
            reader.readAsDataURL(file);
        }
        
        function removeTaskImage(event) {
            event.stopPropagation();
            resetTaskImage();
        }
        
        function resetTaskImage() {
            document.getElementById('add-image').value = '';
            document.getElementById('task-image-input').value = '';
            document.getElementById('task-image-preview').classList.add('hidden');
            document.querySelector('.image-upload-placeholder').style.display = 'flex';
            document.querySelector('.image-remove-btn').classList.add('hidden');
        }
        
        function setNowTime() {
            const now = new Date();
            const hours = String(now.getHours()).padStart(2, '0');
            const minutes = String(now.getMinutes()).padStart(2, '0');
            const timeStr = `${hours}:${minutes}`;
            document.getElementById('add-time').value = timeStr;
            // 同步更新开始时间字段
            document.getElementById('add-start-time').value = timeStr;
            document.getElementById('start-time-text').textContent = timeStr;
            showToast(`已设置当前时间 ${timeStr}`);
        }
        
        function setTodayDate() {
            const today = new Date();
            const year = today.getFullYear();
            const month = String(today.getMonth() + 1).padStart(2, '0');
            const day = String(today.getDate()).padStart(2, '0');
            document.getElementById('add-date').value = `${year}-${month}-${day}`;
            document.getElementById('date-display-text').textContent = `${today.getMonth() + 1}月${today.getDate()}日`;
            showToast(`已设置今天 ${today.getMonth() + 1}月${today.getDate()}日`);
        }
        
        // ========== 日期选择器 ==========
        let pickerDate = new Date();
        let selectedPickerDate = new Date();
        
        function openDatePicker() {
            const currentValue = document.getElementById('add-date').value;
            if (currentValue) {
                pickerDate = new Date(currentValue);
                selectedPickerDate = new Date(currentValue);
            } else {
                pickerDate = new Date();
                selectedPickerDate = new Date();
            }
            renderDatePicker();
            document.getElementById('date-picker-overlay').classList.add('show');
        }
        
        function closeDatePicker(e) {
            if (!e || e.target.id === 'date-picker-overlay') {
                document.getElementById('date-picker-overlay').classList.remove('show');
            }
        }
        
        function changePickerMonth(delta) {
            pickerDate.setMonth(pickerDate.getMonth() + delta);
            renderDatePicker();
        }
        
        function renderDatePicker() {
            const year = pickerDate.getFullYear();
            const month = pickerDate.getMonth();
            document.getElementById('picker-month-year').textContent = `${year}年${month + 1}月`;
            
            const daysContainer = document.getElementById('date-picker-days');
            daysContainer.innerHTML = '';
            
            const firstDay = new Date(year, month, 1);
            const lastDay = new Date(year, month + 1, 0);
            const startPadding = firstDay.getDay();
            const daysInMonth = lastDay.getDate();
            
            const today = new Date();
            
            // 上月填充
            const prevMonthLastDay = new Date(year, month, 0).getDate();
            for (let i = startPadding - 1; i >= 0; i--) {
                const day = prevMonthLastDay - i;
                const div = document.createElement('div');
                div.className = 'date-picker-day other-month';
                div.textContent = day;
                daysContainer.appendChild(div);
            }
            
            // 当月日期
            for (let d = 1; d <= daysInMonth; d++) {
                const div = document.createElement('div');
                const isToday = year === today.getFullYear() && 
                               month === today.getMonth() && 
                               d === today.getDate();
                const isSelected = year === selectedPickerDate.getFullYear() && 
                                  month === selectedPickerDate.getMonth() && 
                                  d === selectedPickerDate.getDate();
                
                div.className = 'date-picker-day';
                if (isToday) div.classList.add('today');
                if (isSelected) div.classList.add('selected');
                div.textContent = d;
                div.onclick = () => {
                    selectedPickerDate = new Date(year, month, d);
                    confirmDatePicker();
                };
                daysContainer.appendChild(div);
            }
            
            // 下月填充
            const totalCells = daysContainer.children.length;
            const endPadding = (7 - (totalCells % 7)) % 7;
            for (let d = 1; d <= endPadding; d++) {
                const div = document.createElement('div');
                div.className = 'date-picker-day other-month';
                div.textContent = d;
                daysContainer.appendChild(div);
            }
        }
        
        function confirmDatePicker() {
            const year = selectedPickerDate.getFullYear();
            const month = String(selectedPickerDate.getMonth() + 1).padStart(2, '0');
            const day = String(selectedPickerDate.getDate()).padStart(2, '0');
            const dateStr = `${year}-${month}-${day}`;
            const displayStr = `${selectedPickerDate.getMonth() + 1}月${selectedPickerDate.getDate()}日`;
            
            document.getElementById('add-date').value = dateStr;
            document.getElementById('date-display-text').textContent = displayStr;
            closeDatePicker();
        }
        
        function setPickerToday() {
            selectedPickerDate = new Date();
            pickerDate = new Date();
            confirmDatePicker();
        }
        
        // ========== 时间选择器 ==========
        let selectedHour = 9; // 默认9点
        let selectedMinute = 0;
        let currentTimePickerMode = 'start'; // 'start' 或 'end'
        
        function openTimePicker(mode = 'start') {
            currentTimePickerMode = mode;
            const inputId = mode === 'start' ? 'add-start-time' : 'add-end-time';
            const currentValue = document.getElementById(inputId).value;
            
            if (currentValue) {
                const [h, m] = currentValue.split(':').map(Number);
                selectedHour = h;
                selectedMinute = m;
            }
            renderTimeOptions();
            
            // 更新选择器标题
            const title = mode === 'start' ? '选择开始时间' : '选择结束时间';
            document.querySelector('.time-picker-header span').textContent = title;
            
            document.getElementById('time-picker-overlay').classList.add('show');
        }
        
        function closeTimePicker(e) {
            if (!e || e.target.id === 'time-picker-overlay') {
                document.getElementById('time-picker-overlay').classList.remove('show');
            }
        }
        
        function renderTimeOptions() {
            const hourContainer = document.getElementById('hour-options');
            const minuteContainer = document.getElementById('minute-options');
            
            // 渲染小时 (0-23, 24小时制)
            hourContainer.innerHTML = '';
            for (let h = 0; h <= 23; h++) {
                const div = document.createElement('div');
                div.className = 'time-option' + (h === selectedHour ? ' selected' : '');
                div.textContent = String(h).padStart(2, '0');
                div.onclick = () => {
                    selectedHour = h;
                    renderTimeOptions();
                };
                hourContainer.appendChild(div);
            }
            
            // 渲染分钟 (0-55, 步进5)
            minuteContainer.innerHTML = '';
            for (let m = 0; m < 60; m += 5) {
                const div = document.createElement('div');
                div.className = 'time-option' + (m === selectedMinute ? ' selected' : '');
                div.textContent = String(m).padStart(2, '0');
                div.onclick = () => {
                    selectedMinute = m;
                    renderTimeOptions();
                };
                minuteContainer.appendChild(div);
            }
            
            // 滚动到选中项
            setTimeout(() => {
                const selectedH = hourContainer.querySelector('.selected');
                const selectedM = minuteContainer.querySelector('.selected');
                if (selectedH) selectedH.scrollIntoView({ block: 'center' });
                if (selectedM) selectedM.scrollIntoView({ block: 'center' });
            }, 50);
        }
        
        function confirmTimePicker() {
            const timeStr = `${String(selectedHour).padStart(2, '0')}:${String(selectedMinute).padStart(2, '0')}`;
            
            if (currentTimePickerMode === 'start') {
                document.getElementById('add-start-time').value = timeStr;
                document.getElementById('start-time-text').textContent = timeStr;
                // 同步更新兼容性字段
                document.getElementById('add-time').value = timeStr;
                
                // 自动调整结束时间（如果结束时间早于开始时间）
                const endTime = document.getElementById('add-end-time').value;
                if (endTime && endTime <= timeStr) {
                    // 默认设置为开始时间后30分钟
                    const [h, m] = timeStr.split(':').map(Number);
                    let newEndH = h;
                    let newEndM = m + 30;
                    if (newEndM >= 60) {
                        newEndH++;
                        newEndM -= 60;
                    }
                    const newEndTimeStr = `${String(newEndH).padStart(2, '0')}:${String(newEndM).padStart(2, '0')}`;
                    document.getElementById('add-end-time').value = newEndTimeStr;
                    document.getElementById('end-time-text').textContent = newEndTimeStr;
                }
            } else {
                document.getElementById('add-end-time').value = timeStr;
                document.getElementById('end-time-text').textContent = timeStr;
            }
            
            closeTimePicker();
        }
        
        function closeAddPanel(e) {
            if (!e || e.target.id === 'add-panel-overlay') {
                document.getElementById('add-panel-overlay').classList.remove('show');
                
                // 重置编辑状态
                if (window.editingTaskId) {
                    const addBtn = document.querySelector('.add-panel .btn-primary');
                    if (addBtn) {
                        addBtn.textContent = '添加任务';
                        addBtn.onclick = addTask;
                    }
                    window.editingTaskId = null;
                }
            }
        }
        
        function addTask() {
            const name = document.getElementById('add-name').value.trim();
            const time = document.getElementById('add-time').value;
            const endTime = document.getElementById('add-end-time').value;
            const date = document.getElementById('add-date').value;
            const icon = document.getElementById('add-icon').value;
            
            if (!name || !time || !date) {
                showToast('请填写完整信息');
                return;
            }
            
            const image = document.getElementById('add-image').value;
            
            const task = {
                id: Date.now().toString(),
                name,
                time,
                endTime: endTime || '',
                icon,
                image,
                date: new Date(date).toISOString(),
                completed: false
            };
            
            // 如果启用了团队模式，添加成员ID
            if (appSettings.teamMode && appSettings.currentMemberId) {
                task.memberId = appSettings.currentMemberId;
            }
            
            // 添加奖励数据
            const rewardType = document.getElementById('add-reward-type').value;
            const rewardData = document.getElementById('add-reward-data').value;
            if (rewardType && rewardData) {
                task.rewardType = rewardType;
                task.rewardData = rewardData;
            }
            
            tasks.push(task);
            
            saveTasks();
            document.getElementById('add-name').value = '';
            
            // 重置奖励区域
            resetRewardSection();
            
            const addDate = new Date(date);
            if (addDate.toDateString() !== currentDate.toDateString()) {
                currentDate = addDate;
            }
            
            renderAll();
            closeAddPanel();
            showToast('任务已添加');
        }

        function editTask(id, event) {
            event.stopPropagation();
            const task = tasks.find(t => t.id === id);
            if (!task) return;
            
            // 保存原始任务ID
            window.editingTaskId = id;
            
            // 打开添加面板（先打开，避免覆盖值）
            openAddPanelForEdit();
            
            // 填充任务数据到表单
            document.getElementById('add-name').value = task.name;
            document.getElementById('add-time').value = task.time;
            document.getElementById('add-date').value = new Date(task.date).toISOString().split('T')[0];
            document.getElementById('add-icon').value = task.icon || '';
            document.getElementById('add-image').value = task.image || '';
            
            // 同步更新开始时间显示
            if (task.time) {
                document.getElementById('add-start-time').value = task.time;
                document.getElementById('start-time-text').textContent = task.time;
            }
            
            // 同步更新结束时间显示
            if (task.endTime) {
                document.getElementById('add-end-time').value = task.endTime;
                document.getElementById('end-time-text').textContent = task.endTime;
            } else {
                document.getElementById('add-end-time').value = '';
                document.getElementById('end-time-text').textContent = '--:--';
            }
            
            // 如果有图片，显示图片预览
            if (task.image) {
                const previewImg = document.getElementById('task-image-preview');
                const placeholder = document.querySelector('.image-upload-placeholder');
                const removeBtn = document.querySelector('.image-remove-btn');
                if (previewImg && placeholder) {
                    previewImg.src = task.image;
                    previewImg.classList.remove('hidden');
                    placeholder.style.display = 'none';
                    if (removeBtn) removeBtn.classList.remove('hidden');
                }
            }
            
            // 更新日期显示
            const taskDate = new Date(task.date);
            document.getElementById('date-display-text').textContent = `${taskDate.getMonth() + 1}月${taskDate.getDate()}日`;
            
            // 修改按钮文本
            const addBtn = document.querySelector('.add-panel .btn-primary');
            if (addBtn) {
                addBtn.textContent = '保存修改';
                addBtn.onclick = updateTask;
            }
        }
        
        // 用于编辑时打开面板（不重置表单值）
        function openAddPanelForEdit() {
            // 重置图片上传
            resetTaskImage();
            // 重置奖励区域
            resetRewardSection();
            document.getElementById('add-panel-overlay').classList.add('show');
            document.getElementById('add-name').focus();
        }

        function updateTask() {
            const id = window.editingTaskId;
            if (!id) return;
            
            const task = tasks.find(t => t.id === id);
            if (!task) return;
            
            const name = document.getElementById('add-name').value.trim();
            const time = document.getElementById('add-time').value;
            const endTime = document.getElementById('add-end-time').value;
            const date = document.getElementById('add-date').value;
            const icon = document.getElementById('add-icon').value;
            
            if (!name || !time || !date) {
                showToast('请填写完整信息');
                return;
            }
            
            const image = document.getElementById('add-image').value;
            
            // 更新任务信息
            task.name = name;
            task.time = time;
            task.endTime = endTime || '';
            task.icon = icon;
            task.image = image;
            task.date = new Date(date).toISOString();
            
            saveTasks();
            document.getElementById('add-name').value = '';
            
            const updateDate = new Date(date);
            if (updateDate.toDateString() !== currentDate.toDateString()) {
                currentDate = updateDate;
            }
            
            renderAll();
            closeAddPanel();
            showToast('任务已更新');
            
            // 重置按钮
            const addBtn = document.querySelector('.add-panel .btn-primary');
            if (addBtn) {
                addBtn.textContent = '添加任务';
                addBtn.onclick = addTask;
            }
            
            window.editingTaskId = null;
        }

        // 新的确认删除模式 - 先标记，再确认删除
        let pendingDeleteId = null;
        let pendingDeleteTimeout = null;
        
        function deleteTask(id, event) {
            event.stopPropagation();
            
            // 如果已有待删除的任务，先取消它
            if (pendingDeleteId && pendingDeleteId !== id) {
                cancelPendingDelete();
            }
            
            // 如果点击的是同一个任务，执行删除
            if (pendingDeleteId === id) {
                executeDelete(id);
                return;
            }
            
            // 标记为待删除状态
            pendingDeleteId = id;
            
            // 找到所有视图中的对应元素并添加确认样式
            const taskSelectors = [
                `.task-item[data-id="${id}"] .task-delete`,
                `.time-slot-task[data-id="${id}"] .delete`,
                `.week-task-item[data-id="${id}"] .delete`
            ];
            
            taskSelectors.forEach(selector => {
                const btn = document.querySelector(selector);
                if (btn) {
                    btn.classList.add('task-delete-confirm');
                    // 更改图标为确认图标
                    btn.innerHTML = `
                        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <polyline points="20 6 9 17 4 12"></polyline>
                        </svg>
                    `;
                    btn.title = '点击确认删除';
                }
            });
            
            showToast('再次点击确认删除', 2000);
            
            // 5秒后自动取消待删除状态
            pendingDeleteTimeout = setTimeout(() => {
                cancelPendingDelete();
            }, 5000);
        }
        
        function cancelPendingDelete() {
            if (!pendingDeleteId) return;
            
            const id = pendingDeleteId;
            const taskSelectors = [
                `.task-item[data-id="${id}"] .task-delete`,
                `.time-slot-task[data-id="${id}"] .delete`,
                `.week-task-item[data-id="${id}"] .delete`
            ];
            
            taskSelectors.forEach(selector => {
                const btn = document.querySelector(selector);
                if (btn) {
                    btn.classList.remove('task-delete-confirm');
                    // 恢复原始删除图标
                    btn.innerHTML = `
                        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <polyline points="3 6 5 6 21 6"></polyline>
                            <path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"></path>
                        </svg>
                    `;
                    btn.title = '删除';
                }
            });
            
            pendingDeleteId = null;
            if (pendingDeleteTimeout) {
                clearTimeout(pendingDeleteTimeout);
                pendingDeleteTimeout = null;
            }
        }
        
        function executeDelete(id) {
            // 清除待删除状态
            pendingDeleteId = null;
            if (pendingDeleteTimeout) {
                clearTimeout(pendingDeleteTimeout);
                pendingDeleteTimeout = null;
            }
            
            // 查找所有视图中对应的任务元素
            const taskSelectors = [
                `.task-item[data-id="${id}"]`,
                `.time-slot-task[data-id="${id}"]`,
                `.week-task-item[data-id="${id}"]`
            ];
            
            let taskElement = null;
            for (const selector of taskSelectors) {
                taskElement = document.querySelector(selector);
                if (taskElement) break;
            }
            
            // 如果找到任务元素，先播放动画
            if (taskElement) {
                taskElement.classList.add('animating-delete');
                setTimeout(() => {
                    tasks = tasks.filter(t => t.id !== id);
                    saveTasks();
                    renderAll();
                    showToast('任务已删除');
                }, 350);
            } else {
                tasks = tasks.filter(t => t.id !== id);
                saveTasks();
                renderAll();
                showToast('任务已删除');
            }
        }
        
        // ========== 批量删除功能 ==========
        
        function toggleBatchDeleteMode() {
            isBatchDeleteMode = !isBatchDeleteMode;
            selectedTaskIds.clear();
            
            const bar = document.getElementById('batch-delete-bar');
            const btn = document.getElementById('batch-mode-btn');
            
            if (isBatchDeleteMode) {
                bar.classList.remove('hidden');
                if (btn) btn.classList.add('active');
                showToast('批量删除模式：点击任务选择要删除的项目', 3000);
            } else {
                bar.classList.add('hidden');
                if (btn) btn.classList.remove('active');
                cancelPendingDelete();
            }
            
            renderAll();
            updateBatchDeleteUI();
        }
        
        function toggleTaskSelection(id) {
            if (!isBatchDeleteMode) return;
            
            if (selectedTaskIds.has(id)) {
                selectedTaskIds.delete(id);
            } else {
                selectedTaskIds.add(id);
            }
            
            updateBatchDeleteUI();
            renderListView(); // 重新渲染以更新选中状态
        }
        
        function updateBatchDeleteUI() {
            const countEl = document.getElementById('selected-count');
            if (countEl) {
                countEl.textContent = selectedTaskIds.size;
            }
            
            // 更新所有任务项的选中状态显示
            document.querySelectorAll('.task-item').forEach(item => {
                const id = item.dataset.id;
                if (selectedTaskIds.has(id)) {
                    item.classList.add('batch-selected');
                } else {
                    item.classList.remove('batch-selected');
                }
            });
        }
        
        function confirmBatchDelete() {
            if (selectedTaskIds.size === 0) {
                showToast('请先选择要删除的任务');
                return;
            }
            
            const count = selectedTaskIds.size;
            
            if (!confirm(`确定要删除选中的 ${count} 个任务吗？`)) {
                return;
            }
            
            // 添加删除动画
            selectedTaskIds.forEach(id => {
                const item = document.querySelector(`.task-item[data-id="${id}"]`);
                if (item) item.classList.add('animating-delete');
            });
            
            setTimeout(() => {
                tasks = tasks.filter(t => !selectedTaskIds.has(t.id));
                saveTasks();
                selectedTaskIds.clear();
                isBatchDeleteMode = false;
                document.getElementById('batch-delete-bar').classList.add('hidden');
                const btn = document.getElementById('batch-mode-btn');
                if (btn) btn.classList.remove('active');
                renderAll();
                showToast(`已删除 ${count} 个任务`);
            }, 350);
        }
        
        function selectAllTasks() {
            const dayTasks = getTasksForDate(currentDate);
            if (isBatchDeleteMode) {
                dayTasks.forEach(t => selectedTaskIds.add(t.id));
                updateBatchDeleteUI();
                renderListView();
            }
        }
        
        function showToast(msg, duration = 2500) {
            const toast = document.getElementById('toast');
            toast.textContent = msg;
            toast.classList.add('show');
            setTimeout(() => toast.classList.remove('show'), duration);
        }

        function isSameDay(date1, date2) {
            const d1 = new Date(date1);
            const d2 = new Date(date2);
            return d1.getFullYear() === d2.getFullYear() &&
                   d1.getMonth() === d2.getMonth() &&
                   d1.getDate() === d2.getDate();
        }
        
        document.addEventListener('keydown', (e) => {
            // 忽略输入框中的快捷键
            if (e.target.tagName === 'INPUT' || e.target.tagName === 'TEXTAREA' || e.target.isContentEditable) {
                if (e.key === 'Escape') {
                    e.target.blur();
                }
                return;
            }
            
            const key = e.key.toLowerCase();
            
            if (e.key === 'Escape') {
                closeAddPanel();
                closeCityModal();
                closeHelpModal();
                closeDatePicker();
                closeTimePicker();
                closeSettingsModal();
            } else if (key === '?' || key === '/') {
                e.preventDefault();
                openHelpModal();
            } else if (key === 'n') {
                e.preventDefault();
                openAddPanel();
            }
        });
        
        // ========== 任务完成奖励功能 ==========
        
        let mediaRecorder = null;
        let recordedChunks = [];
        let recordingTimer = null;
        let recordingSeconds = 0;
        
        // 选择奖励类型
        function selectRewardType(type) {
            // 更新按钮状态
            document.querySelectorAll('.reward-type-btn').forEach(btn => btn.classList.remove('active'));
            document.getElementById(`reward-type-${type}`).classList.add('active');
            
            // 隐藏所有区域
            document.getElementById('recording-area').classList.add('hidden');
            document.getElementById('video-upload-container').classList.add('hidden');
            
            // 更新隐藏字段
            document.getElementById('add-reward-type').value = type === 'none' ? '' : type;
            
            // 显示对应区域
            if (type === 'audio') {
                document.getElementById('recording-area').classList.remove('hidden');
            } else if (type === 'video') {
                document.getElementById('video-upload-container').classList.remove('hidden');
            }
            
            // 更新区域样式
            const section = document.getElementById('reward-section');
            if (type === 'none') {
                section.classList.remove('has-reward');
            } else {
                section.classList.add('has-reward');
            }
        }
        
        // 开始/停止录音
        async function toggleRecording() {
            const recordBtn = document.getElementById('record-btn');
            const recordingWave = document.getElementById('recording-wave');
            const recordingHint = document.getElementById('recording-hint');
            
            if (mediaRecorder && mediaRecorder.state === 'recording') {
                // 停止录音
                mediaRecorder.stop();
                recordBtn.classList.remove('recording');
                recordingWave.classList.add('hidden');
                recordingHint.textContent = '点击重新录音';
                clearInterval(recordingTimer);
                
                // 释放麦克风
                if (mediaRecorder.stream) {
                    mediaRecorder.stream.getTracks().forEach(track => track.stop());
                }
            } else {
                // 开始录音
                try {
                    const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
                    mediaRecorder = new MediaRecorder(stream);
                    recordedChunks = [];
                    
                    mediaRecorder.ondataavailable = (e) => {
                        if (e.data.size > 0) {
                            recordedChunks.push(e.data);
                        }
                    };
                    
                    mediaRecorder.onstop = () => {
                        const blob = new Blob(recordedChunks, { type: 'audio/webm' });
                        const audioUrl = URL.createObjectURL(blob);
                        
                        // 转换为base64存储
                        const reader = new FileReader();
                        reader.onloadend = () => {
                            document.getElementById('add-reward-data').value = reader.result;
                            document.getElementById('recorded-audio-player').src = audioUrl;
                            document.getElementById('recorded-audio').classList.remove('hidden');
                        };
                        reader.readAsDataURL(blob);
                    };
                    
                    mediaRecorder.start();
                    recordBtn.classList.add('recording');
                    recordingWave.classList.remove('hidden');
                    recordingHint.textContent = '正在录音...点击停止';
                    
                    // 计时器
                    recordingSeconds = 0;
                    updateRecordingTime();
                    recordingTimer = setInterval(updateRecordingTime, 1000);
                    
                } catch (err) {
                    console.error('无法访问麦克风:', err);
                    alert('无法访问麦克风，请检查权限设置');
                }
            }
        }
        
        // 更新录音时间显示
        function updateRecordingTime() {
            recordingSeconds++;
            const mins = Math.floor(recordingSeconds / 60).toString().padStart(2, '0');
            const secs = (recordingSeconds % 60).toString().padStart(2, '0');
            document.getElementById('recording-time').textContent = `${mins}:${secs}`;
        }
        
        // 处理视频上传
        function handleRewardVideoUpload(event) {
            const file = event.target.files[0];
            if (!file) return;
            
            // 检查文件大小（最大20MB）
            if (file.size > 20 * 1024 * 1024) {
                alert('视频文件太大，请选择小于20MB的文件');
                return;
            }
            
            const reader = new FileReader();
            reader.onloadend = () => {
                const base64Data = reader.result;
                document.getElementById('add-reward-data').value = base64Data;
                document.getElementById('uploaded-video-player').src = base64Data;
                document.getElementById('uploaded-video-name').textContent = file.name;
                document.getElementById('uploaded-video').classList.remove('hidden');
                document.getElementById('video-upload-area').classList.add('hidden');
            };
            reader.readAsDataURL(file);
        }
        
        // 删除奖励
        function removeReward() {
            document.getElementById('add-reward-data').value = '';
            document.getElementById('add-reward-type').value = '';
            
            // 重置录音区域
            document.getElementById('recorded-audio').classList.add('hidden');
            document.getElementById('recorded-audio-player').src = '';
            document.getElementById('recording-time').textContent = '00:00';
            document.getElementById('recording-hint').textContent = '点击开始录音';
            
            // 重置视频区域
            document.getElementById('uploaded-video').classList.add('hidden');
            document.getElementById('uploaded-video-player').src = '';
            document.getElementById('video-upload-area').classList.remove('hidden');
            document.getElementById('reward-video-input').value = '';
            
            // 重置选择
            selectRewardType('none');
        }
        
        // 重置奖励区域（添加任务后调用）
        function resetRewardSection() {
            selectRewardType('none');
            document.getElementById('add-reward-data').value = '';
            document.getElementById('add-reward-type').value = '';
            document.getElementById('recorded-audio').classList.add('hidden');
            document.getElementById('uploaded-video').classList.add('hidden');
            document.getElementById('video-upload-area').classList.remove('hidden');
            document.getElementById('recording-time').textContent = '00:00';
            document.getElementById('recording-hint').textContent = '点击开始录音';
        }
        
        // 显示任务完成奖励弹窗
        function showTaskReward(task) {
            if (!task.rewardType || !task.rewardData) return;
            
            const modal = document.getElementById('reward-modal');
            const container = document.getElementById('reward-media-container');
            const taskNameEl = document.getElementById('reward-task-name');
            const labelEl = document.getElementById('reward-label-text');
            
            // 设置任务名称
            taskNameEl.textContent = `完成：${task.name}`;
            
            // 清空容器
            container.innerHTML = '';
            
            // 根据奖励类型插入媒体
            if (task.rewardType === 'audio') {
                labelEl.textContent = '🎤 听听爸爸妈妈说的话';
                const audio = document.createElement('audio');
                audio.src = task.rewardData;
                audio.controls = true;
                audio.autoplay = true;
                container.appendChild(audio);
            } else if (task.rewardType === 'video') {
                labelEl.textContent = '🎬 看看爸爸妈妈的鼓励';
                const video = document.createElement('video');
                video.src = task.rewardData;
                video.controls = true;
                video.autoplay = true;
                container.appendChild(video);
            }
            
            // 显示弹窗
            modal.classList.add('show');
            
            // 触发庆祝动画
            createConfetti();
        }
        
        // 关闭奖励弹窗
        function closeRewardModal() {
            const modal = document.getElementById('reward-modal');
            const container = document.getElementById('reward-media-container');
            
            // 停止播放
            const media = container.querySelector('audio, video');
            if (media) {
                media.pause();
                media.src = '';
            }
            
            modal.classList.remove('show');
        }
        
        // ========== 辅助功能：紧急情况、外出包、药物、治疗 ==========
        
        // 存储键名生成函数
        function getEmergencyKey() {
            return getUserStorageKey('emergency-data');
        }
        
        function getPackingKey() {
            return getUserStorageKey('packing-data');
        }
        
        function getMedicineKey() {
            return getUserStorageKey('medicine-data');
        }
        
        function getTherapyKey() {
            return getUserStorageKey('therapy-data');
        }
        
        function getSidebarToolsCollapsedKey() {
            return getUserStorageKey('sidebar-tools-collapsed');
        }
        
        // 初始化侧边栏工具折叠状态
        function initSidebarToolsState() {
            const isCollapsed = localStorage.getItem(getSidebarToolsCollapsedKey()) === 'true';
            const container = document.getElementById('sidebar-tools');
            if (isCollapsed) {
                container.classList.add('collapsed');
            }
        }
        
        function toggleSidebarTools() {
            const container = document.getElementById('sidebar-tools');
            const isCollapsed = container.classList.toggle('collapsed');
            localStorage.setItem(getSidebarToolsCollapsedKey(), isCollapsed);
        }
        
        // ========== 紧急情况功能 ==========
        let emergencyData = {
            contacts: [],
            phrases: [
                { id: 'p1', text: '我需要帮助', icon: '🆘' },
                { id: 'p2', text: '我不舒服', icon: '😣' },
                { id: 'p3', text: '我想回家', icon: '🏠' },
                { id: 'p4', text: '请打电话给我妈妈/爸爸', icon: '📞' },
                { id: 'p5', text: '我感到焦虑', icon: '😰' },
                { id: 'p6', text: '我需要安静一下', icon: '🤫' }
            ]
        };
        
        // 预设外出场景清单
        const packingScenes = {
            school: {
                name: '上学',
                icon: '🎒',
                items: [
                    { id: 's1', name: '书包', icon: '🎒' },
                    { id: 's2', name: '水杯', icon: '🥤' },
                    { id: 's3', name: '口罩', icon: '😷' },
                    { id: 's4', name: '文具盒', icon: '✏️' },
                    { id: 's5', name: '作业本', icon: '📓' },
                    { id: 's6', name: '纸巾', icon: '🧻' },
                    { id: 's7', name: '备用衣物', icon: '👕' },
                    { id: 's8', name: '安抚物品', icon: '🧸' }
                ]
            },
            hospital: {
                name: '医院',
                icon: '🏥',
                items: [
                    { id: 'h1', name: '医保卡/就诊卡', icon: '💳' },
                    { id: 'h2', name: '病历本', icon: '📋' },
                    { id: 'h3', name: '口罩', icon: '😷' },
                    { id: 'h4', name: '水杯', icon: '🥤' },
                    { id: 'h5', name: '零食', icon: '🍪' },
                    { id: 'h6', name: '安抚物品', icon: '🧸' },
                    { id: 'h7', name: '备用衣物', icon: '👕' },
                    { id: 'h8', name: '湿巾', icon: '🧼' }
                ]
            },
            supermarket: {
                name: '超市',
                icon: '🛒',
                items: [
                    { id: 'm1', name: '购物袋', icon: '🛍️' },
                    { id: 'm2', name: '口罩', icon: '😷' },
                    { id: 'm3', name: '钱包/手机', icon: '💰' },
                    { id: 'm4', name: '购物清单', icon: '📝' },
                    { id: 'm5', name: '水杯', icon: '🥤' },
                    { id: 'm6', name: '安抚物品', icon: '🧸' }
                ]
            },
            park: {
                name: '公园',
                icon: '🌳',
                items: [
                    { id: 'pk1', name: '水壶', icon: '🥤' },
                    { id: 'pk2', name: '防晒霜', icon: '🧴' },
                    { id: 'pk3', name: '帽子', icon: '👒' },
                    { id: 'pk4', name: '湿巾/纸巾', icon: '🧻' },
                    { id: 'pk5', name: '零食', icon: '🍪' },
                    { id: 'pk6', name: '玩具', icon: '🪁' },
                    { id: 'pk7', name: '备用衣物', icon: '👕' },
                    { id: 'pk8', name: '安抚物品', icon: '🧸' }
                ]
            }
        };
        
        let currentPackingScene = 'school';
        let packingChecklist = {};
        
        let medicineData = { medicines: [], records: [] };
        let therapyData = { therapists: [], appointments: [] };
        
        // 加载紧急数据
        function loadEmergencyData() {
            const saved = localStorage.getItem(getEmergencyKey());
            if (saved) {
                const data = JSON.parse(saved);
                emergencyData.contacts = data.contacts || [];
                if (data.phrases) {
                    emergencyData.phrases = data.phrases;
                }
            }
        }
        
        function saveEmergencyData() {
            localStorage.setItem(getEmergencyKey(), JSON.stringify(emergencyData));
        }
        
        function openEmergencyModal() {
            loadEmergencyData();
            renderEmergencyContacts();
            renderEmergencyPhrases();
            document.getElementById('emergency-modal').classList.add('show');
        }
        
        function closeEmergencyModal() {
            document.getElementById('emergency-modal').classList.remove('show');
        }
        
        function openEmergencyFullscreen() {
            document.getElementById('emergency-fullscreen').classList.add('show');
            renderFullscreenContacts();
        }
        
        function closeEmergencyFullscreen() {
            document.getElementById('emergency-fullscreen').classList.remove('show');
        }
        
        function renderEmergencyContacts() {
            const container = document.getElementById('emergency-contacts-list');
            if (emergencyData.contacts.length === 0) {
                container.innerHTML = '<p style="color: var(--text-muted); text-align: center; padding: 20px;">暂无紧急联系人，请点击下方按钮添加</p>';
                return;
            }
            
            container.innerHTML = emergencyData.contacts.map(contact => `
                <div class="medicine-card">
                    <div class="medicine-header">
                        <div class="medicine-icon">👤</div>
                        <div class="medicine-info">
                            <div class="medicine-name">${escapeHtml(contact.name)}</div>
                            <div class="medicine-dose">${escapeHtml(contact.relation)} · ${escapeHtml(contact.phone)}</div>
                        </div>
                        <div class="medicine-actions">
                            <button class="medicine-btn" onclick="callEmergencyContact('${contact.phone}')">📞 拨打</button>
                            <button class="medicine-btn" onclick="deleteEmergencyContact('${contact.id}')">删除</button>
                        </div>
                    </div>
                </div>
            `).join('');
        }
        
        function renderFullscreenContacts() {
            const container = document.getElementById('fullscreen-contacts');
            if (emergencyData.contacts.length === 0) {
                container.innerHTML = '<p style="text-align: center; padding: 20px; opacity: 0.8;">暂无紧急联系人</p>';
                return;
            }
            
            container.innerHTML = emergencyData.contacts.map(contact => `
                <div class="emergency-contact-card" onclick="callEmergencyContact('${contact.phone}')">
                    <div class="emergency-contact-avatar">👤</div>
                    <div class="emergency-contact-info">
                        <div class="emergency-contact-name">${escapeHtml(contact.name)}</div>
                        <div class="emergency-contact-relation">${escapeHtml(contact.relation)}</div>
                        <div class="emergency-contact-phone">${escapeHtml(contact.phone)}</div>
                    </div>
                    <button class="emergency-call-btn">拨打</button>
                </div>
            `).join('');
        }
        
        function renderEmergencyPhrases() {
            const container = document.getElementById('emergency-phrases-list');
            container.innerHTML = emergencyData.phrases.map(phrase => `
                <button class="emergency-phrase-btn" onclick="speakPhrase('${escapeHtml(phrase.text)}')">
                    <span class="emergency-phrase-icon">${phrase.icon}</span>
                    <span>${escapeHtml(phrase.text)}</span>
                </button>
            `).join('');
        }
        
        function speakPhrase(text) {
            if ('speechSynthesis' in window) {
                const utterance = new SpeechSynthesisUtterance(text);
                utterance.lang = 'zh-CN';
                utterance.rate = 0.9;
                speechSynthesis.speak(utterance);
                showToast('正在播报：' + text);
            } else {
                showToast('您的设备不支持语音播报');
            }
        }
        
        function callEmergencyContact(phone) {
            window.location.href = 'tel:' + phone;
        }
        
        function showAddContactForm() {
            document.getElementById('add-contact-form').classList.remove('hidden');
        }
        
        function hideAddContactForm() {
            document.getElementById('add-contact-form').classList.add('hidden');
            document.getElementById('new-contact-name').value = '';
            document.getElementById('new-contact-phone').value = '';
            document.getElementById('new-contact-relation').value = '';
        }
        
        function addEmergencyContact() {
            const name = document.getElementById('new-contact-name').value.trim();
            const phone = document.getElementById('new-contact-phone').value.trim();
            const relation = document.getElementById('new-contact-relation').value.trim();
            
            if (!name || !phone) {
                showToast('请输入姓名和电话');
                return;
            }
            
            const contact = {
                id: Date.now().toString(),
                name,
                phone,
                relation: relation || '紧急联系人'
            };
            
            emergencyData.contacts.push(contact);
            saveEmergencyData();
            renderEmergencyContacts();
            hideAddContactForm();
            showToast('紧急联系人已添加');
        }
        
        function deleteEmergencyContact(id) {
            if (!confirm('确定要删除这个联系人吗？')) return;
            emergencyData.contacts = emergencyData.contacts.filter(c => c.id !== id);
            saveEmergencyData();
            renderEmergencyContacts();
            showToast('联系人已删除');
        }
        
        // ========== 外出包清单功能 ==========
        function loadPackingData() {
            const saved = localStorage.getItem(getPackingKey());
            if (saved) {
                packingChecklist = JSON.parse(saved);
            }
        }
        
        function savePackingData() {
            localStorage.setItem(getPackingKey(), JSON.stringify(packingChecklist));
        }
        
        function openPackingModal() {
            loadPackingData();
            renderPackingScenes();
            selectPackingScene(currentPackingScene);
            document.getElementById('packing-modal').classList.add('show');
        }
        
        function closePackingModal() {
            document.getElementById('packing-modal').classList.remove('show');
        }
        
        function renderPackingScenes() {
            const container = document.getElementById('packing-scenes');
            container.innerHTML = Object.entries(packingScenes).map(([key, scene]) => `
                <button class="packing-scene-btn ${key === currentPackingScene ? 'active' : ''}" onclick="selectPackingScene('${key}')">
                    <div class="packing-scene-icon">${scene.icon}</div>
                    <div class="packing-scene-name">${scene.name}</div>
                </button>
            `).join('');
        }
        
        function selectPackingScene(sceneKey) {
            currentPackingScene = sceneKey;
            renderPackingScenes();
            renderPackingList();
        }
        
        function renderPackingList() {
            const scene = packingScenes[currentPackingScene];
            const checkedItems = packingChecklist[currentPackingScene] || [];
            const container = document.getElementById('packing-list');
            
            container.innerHTML = scene.items.map(item => {
                const isChecked = checkedItems.includes(item.id);
                return `
                    <div class="packing-item ${isChecked ? 'checked' : ''}" onclick="togglePackingItem('${item.id}')">
                        <div class="packing-checkbox">${isChecked ? '✓' : ''}</div>
                        <div class="packing-item-icon">${item.icon}</div>
                        <div class="packing-item-name">${item.name}</div>
                    </div>
                `;
            }).join('');
            
            // 更新进度
            const total = scene.items.length;
            const checked = checkedItems.length;
            const percent = total > 0 ? Math.round((checked / total) * 100) : 0;
            
            document.getElementById('packing-progress-text').textContent = `${checked}/${total}`;
            document.getElementById('packing-progress-fill').style.width = percent + '%';
        }
        
        function togglePackingItem(itemId) {
            if (!packingChecklist[currentPackingScene]) {
                packingChecklist[currentPackingScene] = [];
            }
            
            const index = packingChecklist[currentPackingScene].indexOf(itemId);
            if (index > -1) {
                packingChecklist[currentPackingScene].splice(index, 1);
            } else {
                packingChecklist[currentPackingScene].push(itemId);
            }
            
            savePackingData();
            renderPackingList();
        }
        
        function resetPackingList() {
            if (!confirm('确定要重置当前清单吗？')) return;
            packingChecklist[currentPackingScene] = [];
            savePackingData();
            renderPackingList();
            showToast('清单已重置');
        }
        
        // ========== 药物提醒功能 ==========
        function loadMedicineData() {
            const saved = localStorage.getItem(getMedicineKey());
            if (saved) {
                medicineData = JSON.parse(saved);
            }
        }
        
        function saveMedicineData() {
            localStorage.setItem(getMedicineKey(), JSON.stringify(medicineData));
        }
        
        function openMedicineModal() {
            loadMedicineData();
            renderMedicineList();
            document.getElementById('medicine-modal').classList.add('show');
        }
        
        function closeMedicineModal() {
            document.getElementById('medicine-modal').classList.remove('show');
            hideAddMedicineForm();
        }
        
        function renderMedicineList() {
            const container = document.getElementById('medicine-list');
            const today = new Date().toDateString();
            
            if (medicineData.medicines.length === 0) {
                container.innerHTML = `
                    <div class="empty-state-small">
                        <div class="empty-state-small-icon">💊</div>
                        <div class="empty-state-small-text">暂无药物提醒</div>
                    </div>
                `;
                return;
            }
            
            container.innerHTML = medicineData.medicines.map(med => {
                const todayRecord = medicineData.records.find(r => 
                    r.medicineId === med.id && new Date(r.date).toDateString() === today
                );
                const isTaken = !!todayRecord;
                
                return `
                    <div class="medicine-card ${isTaken ? 'completed' : ''}">
                        <div class="medicine-header">
                            <div class="medicine-icon">💊</div>
                            <div class="medicine-info">
                                <div class="medicine-name">${escapeHtml(med.name)}</div>
                                <div class="medicine-dose">${escapeHtml(med.dose)} · ${escapeHtml(med.frequency)}</div>
                                <div class="medicine-time">
                                    <span>⏰</span>
                                    <span>${med.time}</span>
                                </div>
                            </div>
                            <div class="medicine-actions">
                                <button class="medicine-btn take ${isTaken ? 'disabled' : ''}" onclick="takeMedicine('${med.id}')" ${isTaken ? 'disabled' : ''}>
                                    ${isTaken ? '已服用' : '服用'}
                                </button>
                                <button class="medicine-btn" onclick="deleteMedicine('${med.id}')">删除</button>
                            </div>
                        </div>
                        ${isTaken ? `
                            <div class="medicine-record">
                                <span>✓</span>
                                <span>已于 ${todayRecord.time} 服用</span>
                            </div>
                        ` : ''}
                    </div>
                `;
            }).join('');
        }
        
        function showAddMedicineForm() {
            document.getElementById('add-medicine-form').classList.remove('hidden');
        }
        
        function hideAddMedicineForm() {
            document.getElementById('add-medicine-form').classList.add('hidden');
            document.getElementById('new-medicine-name').value = '';
            document.getElementById('new-medicine-dose').value = '';
            document.getElementById('new-medicine-time').value = '';
            document.getElementById('new-medicine-freq').value = 'daily';
        }
        
        function addMedicine() {
            const name = document.getElementById('new-medicine-name').value.trim();
            const dose = document.getElementById('new-medicine-dose').value.trim();
            const time = document.getElementById('new-medicine-time').value;
            const frequency = document.getElementById('new-medicine-freq').value;
            
            if (!name || !time) {
                showToast('请输入药物名称和服用时间');
                return;
            }
            
            const medicine = {
                id: Date.now().toString(),
                name,
                dose: dose || '按医嘱',
                time,
                frequency: frequency === 'daily' ? '每天' : '每周'
            };
            
            medicineData.medicines.push(medicine);
            saveMedicineData();
            renderMedicineList();
            hideAddMedicineForm();
            showToast('药物提醒已添加');
        }
        
        function takeMedicine(medicineId) {
            const record = {
                medicineId,
                date: new Date().toISOString(),
                time: new Date().toLocaleTimeString('zh-CN', { hour: '2-digit', minute: '2-digit' })
            };
            
            medicineData.records.push(record);
            saveMedicineData();
            renderMedicineList();
            showToast('已记录服药');
        }
        
        function deleteMedicine(id) {
            if (!confirm('确定要删除这个药物提醒吗？')) return;
            medicineData.medicines = medicineData.medicines.filter(m => m.id !== id);
            medicineData.records = medicineData.records.filter(r => r.medicineId !== id);
            saveMedicineData();
            renderMedicineList();
            showToast('药物提醒已删除');
        }
        
        // ========== 治疗预约功能 ==========
        function loadTherapyData() {
            const saved = localStorage.getItem(getTherapyKey());
            if (saved) {
                therapyData = JSON.parse(saved);
            }
        }
        
        function saveTherapyData() {
            localStorage.setItem(getTherapyKey(), JSON.stringify(therapyData));
        }
        
        function openTherapyModal() {
            loadTherapyData();
            renderTherapyList();
            document.getElementById('therapy-modal').classList.add('show');
        }
        
        function closeTherapyModal() {
            document.getElementById('therapy-modal').classList.remove('show');
            hideAddTherapyForm();
            hideAddTherapyNoteForm();
        }
        
        function renderTherapyList() {
            const container = document.getElementById('therapy-list');
            
            if (therapyData.therapists.length === 0) {
                container.innerHTML = `
                    <div class="empty-state-small">
                        <div class="empty-state-small-icon">🩺</div>
                        <div class="empty-state-small-text">暂无治疗师信息</div>
                    </div>
                `;
                return;
            }
            
            container.innerHTML = therapyData.therapists.map(therapist => {
                const therapistNotes = therapyData.appointments.filter(a => a.therapistId === therapist.id);
                const latestNote = therapistNotes[therapistNotes.length - 1];
                
                return `
                    <div class="therapy-card">
                        <div class="therapy-header">
                            <div class="therapy-icon">👨‍⚕️</div>
                            <div class="therapy-info">
                                <div class="therapy-name">${escapeHtml(therapist.name)}</div>
                                <div class="therapy-type">${escapeHtml(therapist.type)} · ${escapeHtml(therapist.location)}</div>
                            </div>
                            <div class="medicine-actions">
                                <button class="medicine-btn" onclick="showAddTherapyNoteForm('${therapist.id}')">+笔记</button>
                                <button class="medicine-btn" onclick="deleteTherapist('${therapist.id}')">删除</button>
                            </div>
                        </div>
                        <div class="therapy-details">
                            <div class="therapy-detail">
                                <span>📅</span>
                                <span>${escapeHtml(therapist.schedule)}</span>
                            </div>
                        </div>
                        ${latestNote ? `
                            <div class="therapy-notes">
                                <div class="therapy-notes-label">最新笔记 (${formatDateShort(latestNote.date)})</div>
                                <div>${escapeHtml(latestNote.note)}</div>
                            </div>
                        ` : ''}
                    </div>
                `;
            }).join('');
        }
        
        function formatDateShort(dateStr) {
            const date = new Date(dateStr);
            return `${date.getMonth() + 1}/${date.getDate()}`;
        }
        
        function showAddTherapyForm() {
            document.getElementById('add-therapy-form').classList.remove('hidden');
            document.getElementById('add-therapy-note-form').classList.add('hidden');
        }
        
        function hideAddTherapyForm() {
            document.getElementById('add-therapy-form').classList.add('hidden');
            document.getElementById('new-therapy-name').value = '';
            document.getElementById('new-therapy-type').value = '';
            document.getElementById('new-therapy-location').value = '';
            document.getElementById('new-therapy-schedule').value = '';
        }
        
        function addTherapist() {
            const name = document.getElementById('new-therapy-name').value.trim();
            const type = document.getElementById('new-therapy-type').value.trim();
            const location = document.getElementById('new-therapy-location').value.trim();
            const schedule = document.getElementById('new-therapy-schedule').value.trim();
            
            if (!name || !type) {
                showToast('请输入治疗师姓名和类型');
                return;
            }
            
            const therapist = {
                id: Date.now().toString(),
                name,
                type,
                location: location || '待定',
                schedule: schedule || '待定'
            };
            
            therapyData.therapists.push(therapist);
            saveTherapyData();
            renderTherapyList();
            hideAddTherapyForm();
            showToast('治疗师信息已添加');
        }
        
        function deleteTherapist(id) {
            if (!confirm('确定要删除这位治疗师吗？相关笔记也会被删除。')) return;
            therapyData.therapists = therapyData.therapists.filter(t => t.id !== id);
            therapyData.appointments = therapyData.appointments.filter(a => a.therapistId !== id);
            saveTherapyData();
            renderTherapyList();
            showToast('治疗师信息已删除');
        }
        
        let currentTherapyIdForNote = null;
        
        function showAddTherapyNoteForm(therapistId) {
            currentTherapyIdForNote = therapistId;
            document.getElementById('add-therapy-note-form').classList.remove('hidden');
            document.getElementById('add-therapy-form').classList.add('hidden');
            document.getElementById('new-therapy-note').value = '';
        }
        
        function hideAddTherapyNoteForm() {
            document.getElementById('add-therapy-note-form').classList.add('hidden');
            document.getElementById('new-therapy-note').value = '';
            currentTherapyIdForNote = null;
        }
        
        function addTherapyNote() {
            const note = document.getElementById('new-therapy-note').value.trim();
            
            if (!note || !currentTherapyIdForNote) {
                showToast('请输入笔记内容');
                return;
            }
            
            const appointment = {
                id: Date.now().toString(),
                therapistId: currentTherapyIdForNote,
                date: new Date().toISOString(),
                note
            };
            
            therapyData.appointments.push(appointment);
            saveTherapyData();
            renderTherapyList();
            hideAddTherapyNoteForm();
            showToast('治疗笔记已保存');
        }
        
        // 辅助函数：HTML 转义
        function escapeHtml(text) {
            if (!text) return '';
            const div = document.createElement('div');
            div.textContent = text;
            return div.innerHTML;
        }
        
        // 在初始化时加载侧边栏工具状态
        document.addEventListener('DOMContentLoaded', function() {
            initSidebarToolsState();
        });
        
        // ========== Whisper WebAssembly 本地语音识别 ==========
        
        // Whisper 全局变量
        let whisperPipeline = null;
        let whisperModelLoaded = false;
        let whisperRecording = false;
        let whisperAudioContext = null;
        let whisperMediaStream = null;
        let whisperAudioSource = null;
        let whisperScriptProcessor = null;
        let whisperAudioBuffer = [];
        let whisperTargetInput = 'add-name';
        
        // 模型配置
        const WHISPER_MODEL = 'Xenova/whisper-tiny'; // 30MB，适合日常使用
        
        // 动态加载 transformers.js，在 file:// 协议下或加载失败时自动回退
        let transformersLoadAttempted = false;
        let transformersLoadError = false;
        
        async function loadTransformersScript() {
            if (transformersLoadAttempted) return;
            transformersLoadAttempted = true;
            
            // file:// 协议下 Web Worker 受限，直接跳过本地模型加载
            if (location.protocol === 'file:') {
                whisperLog('检测到 file:// 协议，跳过本地模型加载');
                transformersLoadError = true;
                return;
            }
            
            return new Promise((resolve, reject) => {
                const script = document.createElement('script');
                script.src = 'https://cdn.jsdelivr.net/npm/@xenova/transformers@2.17.2/dist/transformers.min.js';
                script.onload = () => {
                    whisperLog('transformers.js 动态加载成功');
                    resolve();
                };
                script.onerror = (e) => {
                    whisperLog('transformers.js 加载失败');
                    transformersLoadError = true;
                    reject(e);
                };
                document.head.appendChild(script);
            });
        }
        
        // 初始化 Whisper
        async function initWhisper() {
            if (whisperPipeline) {
                whisperLog('模型已初始化，跳过');
                return;
            }
            
            whisperLog('开始初始化 Whisper...');
            updateWhisperStatus('loading', '正在加载语音模型 (约 30MB)...');
            
            await loadTransformersScript();
            
            if (transformersLoadError || !window.transformers) {
                whisperLog('错误: transformers.js 未加载或加载失败');
                updateWhisperStatus('error', '本地模式不可用，请使用在线模式');
                const useOnline = confirm('本地语音识别在此环境下不可用（请通过 HTTP 服务器打开页面以获得最佳体验）。\n\n是否切换到在线模式？');
                if (useOnline) {
                    useNativeSpeechRecognition();
                }
                return;
            }
            
            whisperLog('transformers.js 已加载');
            
            try {
                const { pipeline } = window.transformers;
                whisperLog('获取 pipeline 函数成功');
                
                // 使用 automatic-speech-recognition pipeline
                whisperLog('开始加载模型: ' + WHISPER_MODEL);
                
                whisperPipeline = await pipeline(
                    'automatic-speech-recognition',
                    WHISPER_MODEL,
                    {
                        dtype: 'fp32',
                        device: 'cpu',
                        progress_callback: (progress) => {
                            whisperLog('下载进度: ' + JSON.stringify(progress));
                            if (progress.status === 'progress') {
                                const percent = Math.round(progress.progress * 100);
                                updateWhisperStatus('loading', `正在下载模型... ${percent}%`);
                            } else if (progress.status === 'done') {
                                whisperLog('文件下载完成: ' + progress.file);
                            }
                        }
                    }
                );
                
                whisperModelLoaded = true;
                updateWhisperStatus('ready', '模型加载完成！点击开始录音');
                whisperLog('Whisper 模型加载成功！');
                console.log('Whisper 模型加载成功');
                
            } catch (error) {
                whisperLog('模型加载失败: ' + error.message);
                whisperLog('错误详情: ' + (error.stack || '无堆栈'));
                console.error('Whisper 加载失败:', error);
                
                let errorMsg = '模型加载失败';
                if (error.message && error.message.includes('fetch')) {
                    errorMsg = '网络错误，无法下载模型';
                } else if (error.message && error.message.includes('CORS')) {
                    errorMsg = '跨域访问被阻止';
                } else if (error.message && error.message.includes('timeout')) {
                    errorMsg = '下载超时，请检查网络';
                }
                
                updateWhisperStatus('error', errorMsg + '，请使用在线模式');
                
                // 显示切换到在线模式的提示
                const useOnline = confirm('本地模型加载失败。\n\n是否切换到在线模式？\n（需要联网，使用浏览器内置语音识别）');
                if (useOnline) {
                    useNativeSpeechRecognition();
                }
            }
        }
        
        // 更新状态显示
        function updateWhisperStatus(status, message) {
            const statusEl = document.getElementById('whisper-status');
            if (statusEl) {
                statusEl.className = 'whisper-status ' + status;
                statusEl.textContent = message;
            }
        }
        
        // 切换 Whisper 面板
        function toggleWhisperPanel() {
            const panel = document.getElementById('whisper-panel');
            const isShowing = panel.classList.contains('show');
            
            if (isShowing) {
                panel.classList.remove('show');
                stopWhisperRecording();
            } else {
                panel.classList.add('show');
                // 默认在线模式，不再自动初始化 Whisper 本地模型
            }
        }
        
        // 开始录音 - 使用 Web Audio API 直接采集
        async function startWhisperRecording() {
            whisperLog('开始录音函数被调用');
            
            if (!whisperModelLoaded) {
                whisperLog('错误: 模型未加载');
                showToast('请等待模型加载完成');
                return;
            }
            
            try {
                whisperLog('请求麦克风权限...');
                
                // 请求麦克风权限
                whisperMediaStream = await navigator.mediaDevices.getUserMedia({ 
                    audio: {
                        channelCount: 1,
                        sampleRate: 16000,
                        echoCancellation: true,
                        noiseSuppression: true
                    } 
                });
                
                whisperLog('麦克风权限已获取');
                
                // 创建音频上下文
                whisperAudioContext = new (window.AudioContext || window.webkitAudioContext)({
                    sampleRate: 16000
                });
                
                // 确保 AudioContext 处于运行状态（某些浏览器需要）
                if (whisperAudioContext.state === 'suspended') {
                    whisperLog('AudioContext 被挂起，尝试恢复...');
                    await whisperAudioContext.resume();
                }
                
                whisperLog('AudioContext 创建成功，状态: ' + whisperAudioContext.state + ', 采样率: ' + whisperAudioContext.sampleRate);
                
                // 创建音频源
                whisperAudioSource = whisperAudioContext.createMediaStreamSource(whisperMediaStream);
                whisperLog('MediaStreamSource 创建成功');
                
                // 创建 ScriptProcessor 用于采集音频数据
                whisperScriptProcessor = whisperAudioContext.createScriptProcessor(4096, 1, 1);
                whisperAudioBuffer = [];
                
                whisperLog('ScriptProcessor 创建成功，bufferSize: 4096');
                
                // 处理音频数据
                let chunkCount = 0;
                let hasAudioData = false;
                whisperScriptProcessor.onaudioprocess = (event) => {
                    const inputData = event.inputBuffer.getChannelData(0);
                    
                    // 检查是否有实际音频数据（不是所有 0）
                    let maxVolume = 0;
                    for (let i = 0; i < inputData.length; i++) {
                        maxVolume = Math.max(maxVolume, Math.abs(inputData[i]));
                    }
                    
                    whisperAudioBuffer.push(new Float32Array(inputData));
                    chunkCount++;
                    
                    if (maxVolume > 0.01) {
                        hasAudioData = true;
                    }
                    
                    if (chunkCount % 10 === 0) {
                        whisperLog('采集音频块 #' + chunkCount + ', 总样本数: ' + (whisperAudioBuffer.length * 4096) + ', 最大音量: ' + maxVolume.toFixed(4));
                    }
                };
                
                // 3秒后检查是否收到音频数据
                setTimeout(() => {
                    if (whisperRecording && !hasAudioData) {
                        whisperLog('警告: 3秒内未检测到有效音频，请检查麦克风');
                    }
                }, 3000);
                
                // 连接节点
                whisperAudioSource.connect(whisperScriptProcessor);
                whisperScriptProcessor.connect(whisperAudioContext.destination);
                
                whisperLog('音频节点已连接');
                
                whisperRecording = true;
                
                // 更新 UI
                document.getElementById('whisper-mic-btn').classList.add('recording');
                updateWhisperStatus('recording', '正在录音，请说话...（点击停止）');
                document.getElementById('whisper-toggle-btn').textContent = '停止录音';
                
                whisperLog('录音已开始');
                
            } catch (error) {
                whisperLog('录音失败: ' + error.name + ' - ' + error.message);
                console.error('录音失败:', error);
                if (error.name === 'NotAllowedError') {
                    showToast('请允许使用麦克风权限');
                    updateWhisperStatus('error', '麦克风权限被拒绝');
                } else {
                    showToast('无法访问麦克风: ' + error.message);
                    updateWhisperStatus('error', '录音启动失败: ' + error.message);
                }
            }
        }
        
        // 停止录音
        function stopWhisperRecording() {
            whisperLog('停止录音函数被调用');
            
            if (!whisperRecording) {
                whisperLog('警告: 录音状态为 false');
                return;
            }
            
            whisperRecording = false;
            
            // 停止 ScriptProcessor
            if (whisperScriptProcessor) {
                whisperScriptProcessor.disconnect();
                whisperScriptProcessor = null;
                whisperLog('ScriptProcessor 已断开');
            }
            
            // 停止音频源
            if (whisperAudioSource) {
                whisperAudioSource.disconnect();
                whisperAudioSource = null;
                whisperLog('音频源已断开');
            }
            
            // 停止媒体流
            if (whisperMediaStream) {
                whisperMediaStream.getTracks().forEach(track => track.stop());
                whisperMediaStream = null;
                whisperLog('媒体流已停止');
            }
            
            // 关闭音频上下文
            if (whisperAudioContext && whisperAudioContext.state !== 'closed') {
                whisperAudioContext.close();
                whisperAudioContext = null;
                whisperLog('AudioContext 已关闭');
            }
            
            // 更新 UI
            document.getElementById('whisper-mic-btn').classList.remove('recording');
            updateWhisperStatus('loading', '正在识别语音...');
            document.getElementById('whisper-toggle-btn').textContent = '开始录音';
            
            whisperLog('录音已停止，准备处理音频');
            
            // 处理音频数据
            processWhisperAudioBuffer();
        }
        
        // 处理音频缓冲区
        async function processWhisperAudioBuffer() {
            whisperLog('处理音频缓冲区，块数: ' + whisperAudioBuffer.length);
            
            try {
                if (whisperAudioBuffer.length === 0) {
                    whisperLog('错误: 没有音频数据');
                    updateWhisperStatus('error', '没有录到声音，请重试');
                    return;
                }
                
                // 合并所有音频片段
                const totalLength = whisperAudioBuffer.reduce((sum, buf) => sum + buf.length, 0);
                whisperLog('合并音频，总长度: ' + totalLength + ' 样本');
                
                const mergedAudio = new Float32Array(totalLength);
                
                let offset = 0;
                for (const buffer of whisperAudioBuffer) {
                    mergedAudio.set(buffer, offset);
                    offset += buffer.length;
                }
                
                const duration = (mergedAudio.length / 16000).toFixed(2);
                whisperLog('音频时长: ' + duration + ' 秒');
                
                // 音频太短则提示
                if (mergedAudio.length < 16000 * 0.5) {
                    whisperLog('错误: 录音太短 (' + duration + ' 秒)');
                    updateWhisperStatus('error', '录音太短，请多说一点');
                    return;
                }
                
                // 使用 Whisper 进行识别
                updateWhisperStatus('loading', 'AI 正在识别中...');
                whisperLog('调用 Whisper 识别...');
                
                const result = await whisperPipeline(mergedAudio, {
                    language: 'chinese',
                    task: 'transcribe',
                });
                
                whisperLog('识别结果: ' + JSON.stringify(result));
                
                const text = result.text ? result.text.trim() : '';
                
                if (text) {
                    document.getElementById('whisper-result').textContent = text;
                    updateWhisperStatus('ready', '识别完成！点击确认填入');
                    document.getElementById('whisper-confirm-btn').disabled = false;
                    whisperLog('识别成功: ' + text);
                } else {
                    document.getElementById('whisper-result').textContent = '';
                    updateWhisperStatus('error', '未能识别到语音，请重试');
                    document.getElementById('whisper-confirm-btn').disabled = true;
                    whisperLog('识别结果为空');
                }
                
            } catch (error) {
                whisperLog('识别失败: ' + error.message);
                console.error('识别失败:', error);
                updateWhisperStatus('error', '识别失败: ' + error.message);
                showToast('语音识别失败');
            } finally {
                whisperAudioBuffer = [];
                whisperLog('音频缓冲区已清空');
            }
        }
        
        // 确认并填入输入框
        function confirmWhisperResult() {
            const text = document.getElementById('whisper-result').textContent;
            if (!text) return;
            
            // 根据目标选择填入不同的输入框
            const target = document.getElementById('whisper-target').value;
            const inputEl = document.getElementById(target);
            
            if (inputEl) {
                // 如果是任务名称输入框，尝试解析时间
                if (target === 'add-name') {
                    parseAndFillTaskFromVoice(text);
                } else {
                    inputEl.value = text;
                }
                
                showToast('语音已填入');
            }
            
            // 清空结果
            document.getElementById('whisper-result').textContent = '';
            document.getElementById('whisper-confirm-btn').disabled = true;
            
            // 可选：关闭面板
            // toggleWhisperPanel();
        }
        
        // 解析语音创建任务
        function parseAndFillTaskFromVoice(text) {
            // 解析时间（与现有语音助手相同的逻辑）
            let timeStr = '';
            let taskName = text;
            let hour = null;
            let minute = 0;
            
            const patterns = [
                { regex: /(早上|上午|中午|下午|晚上)?\s*(\d{1,2})\s*点\s*(\d{0,2})\s*分?/, type: 'chinese' },
                { regex: /(\d{1,2}):(\d{2})/, type: 'colon' },
                { regex: /(\d{1,2})\s*点半/, type: 'half' }
            ];
            
            for (const p of patterns) {
                const match = text.match(p.regex);
                if (match) {
                    if (p.type === 'chinese') {
                        const period = match[1] || '';
                        hour = parseInt(match[2]);
                        minute = parseInt(match[3]) || 0;
                        if (period === '下午' || period === '晚上') {
                            if (hour !== 12) hour += 12;
                        } else if (period === '早上' || period === '上午') {
                            if (hour === 12) hour = 0;
                        }
                        taskName = text.replace(match[0], '').trim();
                    } else if (p.type === 'colon') {
                        hour = parseInt(match[1]);
                        minute = parseInt(match[2]);
                        taskName = text.replace(match[0], '').trim();
                    } else if (p.type === 'half') {
                        hour = parseInt(match[1]);
                        minute = 30;
                        taskName = text.replace(match[0], '').trim();
                    }
                    break;
                }
            }
            
            // 填入任务名称
            document.getElementById('add-name').value = taskName || text;
            
            // 填入时间
            if (hour !== null) {
                timeStr = String(hour).padStart(2, '0') + ':' + String(minute).padStart(2, '0');
                document.getElementById('add-time').value = timeStr;
                document.getElementById('add-start-time').value = timeStr;
                document.getElementById('start-time-text').textContent = timeStr;
            }
        }
        
        // 在输入框旁边添加语音输入按钮
        function addVoiceInputButtons() {
            // 为任务名称输入框添加语音按钮
            const nameInput = document.getElementById('add-name');
            if (nameInput && !nameInput.parentElement.querySelector('.voice-input-btn')) {
                const wrapper = document.createElement('div');
                wrapper.className = 'voice-input-wrapper';
                nameInput.parentNode.insertBefore(wrapper, nameInput);
                wrapper.appendChild(nameInput);
                
                const voiceBtn = document.createElement('button');
                voiceBtn.className = 'voice-input-btn';
                voiceBtn.innerHTML = '🎤';
                voiceBtn.title = '语音输入';
                voiceBtn.onclick = () => {
                    document.getElementById('whisper-target').value = 'add-name';
                    toggleWhisperPanel();
                };
                wrapper.appendChild(voiceBtn);
            }
        }
        
        // 页面加载完成后添加语音按钮
        document.addEventListener('DOMContentLoaded', function() {
            setTimeout(addVoiceInputButtons, 1000);
        });
        
        // 预加载模型（在后台静默加载）
        function preloadWhisperModel() {
            // 延迟 3 秒后预加载，避免影响页面启动速度
            setTimeout(() => {
                if (!whisperPipeline && !whisperModelLoaded) {
                    console.log('预加载 Whisper 模型...');
                    initWhisper();
                }
            }, 3000);
        }
        
        // 页面加载完成后预加载模型
        document.addEventListener('DOMContentLoaded', preloadWhisperModel);
        
        // ========== 备用：浏览器原生语音识别 ==========
        // 当 Whisper 不可用或用户不想下载模型时使用
        
        let nativeRecognition = null;
        let isNativeRecording = false;
        
        // 切换使用原生语音识别
        function useNativeSpeechRecognition() {
            if (!('webkitSpeechRecognition' in window) && !('SpeechRecognition' in window)) {
                showToast('您的浏览器不支持语音识别');
                return;
            }
            
            // 停止 Whisper 录音（如果正在录音）
            if (whisperRecording) {
                stopWhisperRecording();
            }
            
            if (isNativeRecording) {
                stopNativeRecording();
            } else {
                startNativeRecording();
            }
        }
        
        // 日志记录
        function whisperLog(message) {
            console.log('[Whisper]', message);
            const debugLog = document.getElementById('whisper-debug-log');
            const debugSection = document.getElementById('whisper-debug-section');
            if (debugLog && debugSection) {
                debugSection.style.display = 'block';
                const time = new Date().toLocaleTimeString('zh-CN', {hour12: false});
                debugLog.textContent += `[${time}] ${message}\n`;
                debugLog.scrollTop = debugLog.scrollHeight;
            }
        }
        
        // 智能切换录音（根据模型加载状态）
        function toggleWhisperRecording() {
            whisperLog('切换录音，当前状态: whisperRecording=' + whisperRecording + ', isNativeRecording=' + isNativeRecording);
            
            if (whisperModelLoaded) {
                // Whisper 已加载，使用 Whisper
                if (whisperRecording) {
                    stopWhisperRecording();
                } else {
                    startWhisperRecording();
                }
            } else if (isNativeRecording) {
                // 正在使用原生识别，停止
                stopNativeRecording();
            } else {
                // 默认使用在线模式（原生语音识别），无需下载模型
                useNativeSpeechRecognition();
            }
        }
        
        function startNativeRecording() {
            const SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition;
            nativeRecognition = new SpeechRecognition();
            nativeRecognition.lang = 'zh-CN';
            nativeRecognition.continuous = false;
            nativeRecognition.interimResults = true;
            
            nativeRecognition.onstart = () => {
                isNativeRecording = true;
                document.getElementById('whisper-mic-btn').classList.add('recording');
                updateWhisperStatus('recording', '正在录音（在线模式）...');
                document.getElementById('whisper-toggle-btn').textContent = '停止录音';
                document.getElementById('whisper-toggle-btn').onclick = toggleWhisperRecording;
            };
            
            nativeRecognition.onresult = (event) => {
                let finalTranscript = '';
                let interimTranscript = '';
                
                for (let i = event.resultIndex; i < event.results.length; i++) {
                    const transcript = event.results[i][0].transcript;
                    if (event.results[i].isFinal) {
                        finalTranscript += transcript;
                    } else {
                        interimTranscript += transcript;
                    }
                }
                
                const text = finalTranscript || interimTranscript;
                document.getElementById('whisper-result').textContent = text;
            };
            
            nativeRecognition.onerror = (event) => {
                console.error('语音识别错误:', event.error);
                if (event.error === 'not-allowed') {
                    showToast('请允许使用麦克风权限');
                } else if (event.error === 'network') {
                    showToast('网络错误，请检查网络连接');
                }
                stopNativeRecording();
            };
            
            nativeRecognition.onend = () => {
                if (isNativeRecording) {
                    stopNativeRecording();
                    const text = document.getElementById('whisper-result').textContent;
                    if (text) {
                        updateWhisperStatus('ready', '识别完成！');
                        document.getElementById('whisper-confirm-btn').disabled = false;
                    }
                }
            };
            
            try {
                nativeRecognition.start();
            } catch (e) {
                showToast('无法启动录音');
            }
        }
        
        function stopNativeRecording() {
            isNativeRecording = false;
            if (nativeRecognition) {
                try {
                    nativeRecognition.stop();
                } catch (e) {}
                nativeRecognition = null;
            }
            document.getElementById('whisper-mic-btn').classList.remove('recording');
            document.getElementById('whisper-toggle-btn').textContent = '开始录音';
            document.getElementById('whisper-toggle-btn').onclick = toggleWhisperRecording;
        }
        
        // 检测浏览器是否支持原生语音识别
        function checkNativeSpeechSupport() {
            const hasNativeSupport = 'webkitSpeechRecognition' in window || 'SpeechRecognition' in window;
            const switchBtn = document.getElementById('whisper-switch-mode-btn');
            if (switchBtn && hasNativeSupport) {
                switchBtn.style.display = 'inline-block';
            }
        }
        
        // 页面加载完成后检测
        document.addEventListener('DOMContentLoaded', checkNativeSpeechSupport);
        
        // 诊断录音系统
        async function diagnoseAudioSystem() {
            const results = [];
            
            // 检查浏览器支持
            results.push('浏览器: ' + navigator.userAgent.substring(0, 50) + '...');
            results.push('Transformers.js: ' + (window.transformers ? '已加载 ✓' : '未加载 ✗'));
            results.push('原生语音识别: ' + (('webkitSpeechRecognition' in window || 'SpeechRecognition' in window) ? '支持 ✓' : '不支持 ✗'));
            
            // 检查麦克风权限
            try {
                const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
                results.push('麦克风权限: 已授权 ✓');
                stream.getTracks().forEach(track => track.stop());
            } catch (e) {
                results.push('麦克风权限: ' + e.message + ' ✗');
            }
            
            // 检查 AudioContext
            try {
                const AudioContext = window.AudioContext || window.webkitAudioContext;
                const ctx = new AudioContext();
                results.push('AudioContext: 支持 ✓ (采样率: ' + ctx.sampleRate + 'Hz)');
                ctx.close();
            } catch (e) {
                results.push('AudioContext: 不支持 ✗');
            }
            
            // 检查 ScriptProcessor
            try {
                const AudioContext = window.AudioContext || window.webkitAudioContext;
                const ctx = new AudioContext();
                const processor = ctx.createScriptProcessor(4096, 1, 1);
                results.push('ScriptProcessorNode: 支持 ✓');
                ctx.close();
            } catch (e) {
                results.push('ScriptProcessorNode: 不支持 ✗');
            }
            
            alert('音频系统诊断结果:\n\n' + results.join('\n'));
            console.log('音频系统诊断:', results);
        }
        
        // 添加诊断按钮（开发调试使用）
        // 按 Shift+D 触发诊断
        document.addEventListener('keydown', (e) => {
            if (e.shiftKey && e.key === 'D') {
                diagnoseAudioSystem();
            }
        });

// 注册 Service Worker
        if ('serviceWorker' in navigator) {
            navigator.serviceWorker.register('sw.js')
                .then(reg => console.log('SW 注册成功:', reg.scope))
                .catch(err => console.log('SW 注册失败:', err));
        }

        // 离线状态检测
        function updateOnlineStatus() {
            const offlineBadge = document.getElementById('offline-badge');
            const weatherCard = document.getElementById('weather-card');
            
            if (!navigator.onLine) {
                if (offlineBadge) offlineBadge.classList.remove('hidden');
                // 如果天气正在加载，显示离线提示
                if (weatherCard && weatherCard.querySelector('.weather-loading')) {
                    weatherCard.innerHTML = `
                        <div class="weather-offline">
                            <div style="font-size: 24px; margin-bottom: 8px;">📡</div>
                            <div>当前处于离线模式</div>
                            <div style="font-size: 12px; opacity: 0.7; margin-top: 4px;">天气信息暂不可用</div>
                        </div>
                    `;
                }
            } else {
                if (offlineBadge) offlineBadge.classList.add('hidden');
            }
        }

        window.addEventListener('online', updateOnlineStatus);
        window.addEventListener('offline', updateOnlineStatus);
        window.addEventListener('DOMContentLoaded', updateOnlineStatus);