/**
 * 星序 - 统一应用（多日期版）
 * 支持：标准模式、简化模式、文字批量导入、多日期、重复任务、标签、提醒
 */

// ===== 存储 =====
const Storage = {
    key: 'schedule-unified-v2',
    viewKey: 'schedule-view-mode',
    currentDateKey: 'schedule-current-date',
    settingsKey: 'schedule-settings',
    backupKey: 'schedule-last-backup',
    
    // 获取指定日期的任务
    getTasks(dateStr) {
        const data = localStorage.getItem(this.key);
        if (!data) return [];
        try {
            const allTasks = JSON.parse(data);
            return allTasks.filter(t => t.date === dateStr);
        } catch (e) {
            return [];
        }
    },
    
    // 获取所有任务（用于重复任务生成）
    getAllTasks() {
        const data = localStorage.getItem(this.key);
        if (!data) return [];
        try {
            return JSON.parse(data);
        } catch (e) {
            return [];
        }
    },
    
    // 保存任务（按日期）
    saveTasks(dateStr, tasks) {
        const allData = localStorage.getItem(this.key);
        let allTasks = [];
        if (allData) {
            try { allTasks = JSON.parse(allData); } catch (e) {}
        }
        // 移除该日期的旧任务
        allTasks = allTasks.filter(t => t.date !== dateStr);
        // 添加新任务
        allTasks = [...allTasks, ...tasks];
        localStorage.setItem(this.key, JSON.stringify(allTasks));
        // 同步到 iOS 小组件
        if (window.xingxuNative && window.xingxuNative.ready) {
            window.xingxuNative.postMessage({ action: 'syncTasks' });
        }
    },
    
    // 保存单个任务
    saveTask(task) {
        const allTasks = this.getAllTasks();
        const index = allTasks.findIndex(t => t.id === task.id);
        if (index >= 0) {
            allTasks[index] = task;
        } else {
            allTasks.push(task);
        }
        localStorage.setItem(this.key, JSON.stringify(allTasks));
    },
    
    // 删除任务
    deleteTask(taskId) {
        const allTasks = this.getAllTasks();
        const filtered = allTasks.filter(t => t.id !== taskId);
        localStorage.setItem(this.key, JSON.stringify(filtered));
    },
    
    getViewMode() {
        return localStorage.getItem(this.viewKey) || 'standard';
    },
    
    setViewMode(mode) {
        localStorage.setItem(this.viewKey, mode);
    },
    
    getCurrentDate() {
        const saved = localStorage.getItem(this.currentDateKey);
        return saved || new Date().toISOString().split('T')[0];
    },
    
    setCurrentDate(dateStr) {
        localStorage.setItem(this.currentDateKey, dateStr);
    },
    
    // 获取设置
    getSettings() {
        const data = localStorage.getItem(this.settingsKey);
        if (!data) {
            return {
                notifications: true,
                notificationMinutes: 5,
                defaultTags: ['工作', '学习', '生活', '健康', '娱乐'],
                theme: 'default',
                // 儿童模式设置
                childMode: {
                    enabled: false,
                    largeCards: true,
                    showImages: true,
                    colorCoding: true,
                    fontSize: 'large',
                    highContrast: false,
                    voicePrompts: true
                },
                // 颜色编码设置
                colorCoding: {
                    enabled: true,
                    work: '#3B82F6',
                    study: '#8B5CF6',
                    life: '#10B981',
                    health: '#F59E0B',
                    entertainment: '#EC4899',
                    important: '#EF4444',
                    morning: '#FCD34D',
                    afternoon: '#60A5FA',
                    evening: '#818CF8',
                    default: '#6B7280'
                }
            };
        }
        try {
            return JSON.parse(data);
        } catch (e) {
            return {};
        }
    },
    
    // 保存设置
    saveSettings(settings) {
        localStorage.setItem(this.settingsKey, JSON.stringify(settings));
    },
    
    export() {
        const tasks = this.getAllTasks();
        const blob = new Blob([JSON.stringify(tasks, null, 2)], { type: 'application/json' });
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `schedule-${new Date().toISOString().split('T')[0]}.json`;
        a.click();
        URL.revokeObjectURL(url);
        localStorage.setItem(this.backupKey, Date.now().toString());
    },
    
    // 导出特定日期范围
    exportRange(startDate, endDate) {
        const allTasks = this.getAllTasks();
        const filtered = allTasks.filter(t => t.date >= startDate && t.date <= endDate);
        const blob = new Blob([JSON.stringify(filtered, null, 2)], { type: 'application/json' });
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `schedule-${startDate}-to-${endDate}.json`;
        a.click();
        URL.revokeObjectURL(url);
        localStorage.setItem(this.backupKey, Date.now().toString());
    },
    
    // 导入数据
    import(data) {
        try {
            const tasks = JSON.parse(data);
            if (Array.isArray(tasks)) {
                const allTasks = this.getAllTasks();
                // 合并任务，避免重复
                const existingIds = new Set(allTasks.map(t => t.id));
                const newTasks = tasks.filter(t => !existingIds.has(t.id));
                const merged = [...allTasks, ...newTasks];
                localStorage.setItem(this.key, JSON.stringify(merged));
                return { success: true, count: newTasks.length };
            }
            return { success: false, error: '无效的数据格式' };
        } catch (e) {
            return { success: false, error: e.message };
        }
    }
};

// ===== 状态 =====
let tasks = [];
let currentMode = 'standard';
let detectedTasks = [];
let selectedTaskId = null;
let currentDate = new Date().toISOString().split('T')[0];
let settings = Storage.getSettings();

// 预定义标签颜色
const tagColors = {
    '工作': '#3B82F6',
    '学习': '#8B5CF6',
    '生活': '#10B981',
    '健康': '#F59E0B',
    '娱乐': '#EC4899',
    '重要': '#EF4444',
    '默认': '#6B7280'
};

// ===== 初始化 =====
document.addEventListener('DOMContentLoaded', async () => {
    currentDate = Storage.getCurrentDate();
    tasks = Storage.getTasks(currentDate);
    currentMode = Storage.getViewMode();
    settings = Storage.getSettings();
    
    applyViewMode();
    await updateAllViews();
    setupKeyboard();
    setupNotification();
    checkAndGenerateRepeatingTasks();
    checkBackupReminder();
});

// ===== 日期操作 =====
async function changeDate(dateStr) {
    currentDate = dateStr;
    Storage.setCurrentDate(dateStr);
    tasks = Storage.getTasks(currentDate);
    await updateAllViews();
}

function goToToday() {
    const today = new Date().toISOString().split('T')[0];
    changeDate(today);
}

function goToPrevDay() {
    const date = new Date(currentDate);
    date.setDate(date.getDate() - 1);
    changeDate(date.toISOString().split('T')[0]);
}

function goToNextDay() {
    const date = new Date(currentDate);
    date.setDate(date.getDate() + 1);
    changeDate(date.toISOString().split('T')[0]);
}

// 获取日期范围的任务统计
function getDateRangeStats(startDate, days) {
    const stats = [];
    const start = new Date(startDate);
    
    for (let i = 0; i < days; i++) {
        const date = new Date(start);
        date.setDate(date.getDate() + i);
        const dateStr = date.toISOString().split('T')[0];
        const dayTasks = Storage.getTasks(dateStr);
        
        stats.push({
            date: dateStr,
            total: dayTasks.length,
            completed: dayTasks.filter(t => t.completed).length
        });
    }
    
    return stats;
}

// ===== 视图切换 =====
async function switchToSimple() {
    currentMode = 'simple';
    Storage.setViewMode('simple');
    applyViewMode();
    await updateAllViews();
}

async function switchToStandard() {
    currentMode = 'standard';
    Storage.setViewMode('standard');
    applyViewMode();
    await updateAllViews();
}

function applyViewMode() {
    const standardEl = document.getElementById('standard-mode');
    const simpleEl = document.getElementById('simple-mode');
    
    if (currentMode === 'simple') {
        standardEl.classList.add('hidden');
        simpleEl.classList.remove('hidden');
    } else {
        standardEl.classList.remove('hidden');
        simpleEl.classList.add('hidden');
    }
}

async function updateAllViews() {
    updateDate();
    await renderStandardTasks();
    await renderSimpleTasks();
    updateProgress();
    updateStats();
    renderMiniCalendar();
    
    // 设置默认时间
    const now = new Date();
    now.setHours(now.getHours() + 1);
    now.setMinutes(0);
    const timeStr = `${String(now.getHours()).padStart(2, '0')}:00`;
    
    const quickTime = document.getElementById('quick-time');
    const simpleTime = document.getElementById('simple-time');
    
    if (quickTime) quickTime.value = timeStr;
    if (simpleTime) simpleTime.value = timeStr;
}

function updateDate() {
    const date = new Date(currentDate);
    const weekdays = ['星期日', '星期一', '星期二', '星期三', '星期四', '星期五', '星期六'];
    const months = ['1月', '2月', '3月', '4月', '5月', '6月', '7月', '8月', '9月', '10月', '11月', '12月'];
    const isToday = currentDate === new Date().toISOString().split('T')[0];
    
    const headerDate = document.getElementById('header-date');
    const headerWeekday = document.getElementById('header-weekday');
    if (headerDate) {
        headerDate.textContent = `${date.getFullYear()}年${date.getMonth() + 1}月${date.getDate()}日`;
        if (isToday) {
            headerDate.innerHTML += ' <span class="today-badge">今天</span>';
        }
    }
    if (headerWeekday) headerWeekday.textContent = weekdays[date.getDay()];
    
    const simpleDateSub = document.getElementById('simple-date-sub');
    if (simpleDateSub) simpleDateSub.textContent = `${months[date.getMonth()]}${date.getDate()}日 ${weekdays[date.getDay()]}${isToday ? ' (今天)' : ''}`;
}

function updateStats() {
    const total = tasks.length;
    const completed = tasks.filter(t => t.completed).length;
    const percent = total > 0 ? Math.round((completed / total) * 100) : 0;
    
    const statTotal = document.getElementById('stat-total');
    const statCompleted = document.getElementById('stat-completed');
    const sidebarPercent = document.getElementById('sidebar-percent');
    const sidebarProgress = document.getElementById('sidebar-progress');
    
    if (statTotal) statTotal.textContent = total;
    if (statCompleted) statCompleted.textContent = completed;
    if (sidebarPercent) sidebarPercent.textContent = percent + '%';
    if (sidebarProgress) sidebarProgress.style.width = percent + '%';
}

function updateProgress() {
    const total = tasks.length;
    const completed = tasks.filter(t => t.completed).length;
    const percent = total > 0 ? Math.round((completed / total) * 100) : 0;
    
    const progressText = document.getElementById('progress-text');
    const progressFill = document.getElementById('sidebar-progress');
    const simpleProgressText = document.getElementById('simple-progress-text');
    const simpleProgressBar = document.getElementById('simple-progress-bar');
    
    if (progressText) progressText.textContent = percent + '%';
    if (progressFill) progressFill.style.width = percent + '%';
    if (simpleProgressText) simpleProgressText.textContent = percent + '%';
    if (simpleProgressBar) simpleProgressBar.style.width = percent + '%';
    
    if (total > 0 && completed === total) {
        setTimeout(() => showToast('今日任务全部完成 🎉'), 500);
    }
}

// ===== 迷你日历 =====
function renderMiniCalendar() {
    const container = document.getElementById('mini-calendar');
    if (!container) return;
    
    const date = new Date(currentDate);
    const year = date.getFullYear();
    const month = date.getMonth();
    const today = new Date().toISOString().split('T')[0];
    
    const firstDay = new Date(year, month, 1).getDay();
    const daysInMonth = new Date(year, month + 1, 0).getDate();
    const daysInPrevMonth = new Date(year, month, 0).getDate();
    
    let html = `
        <div class="mini-cal-header">
            <button onclick="changeDate('${new Date(year, month - 1, 1).toISOString().split('T')[0]}')">‹</button>
            <span>${year}年${month + 1}月</span>
            <button onclick="changeDate('${new Date(year, month + 1, 1).toISOString().split('T')[0]}')">›</button>
        </div>
        <div class="mini-cal-grid">
            <div class="mini-cal-day">日</div>
            <div class="mini-cal-day">一</div>
            <div class="mini-cal-day">二</div>
            <div class="mini-cal-day">三</div>
            <div class="mini-cal-day">四</div>
            <div class="mini-cal-day">五</div>
            <div class="mini-cal-day">六</div>
    `;
    
    // 上月日期
    for (let i = firstDay - 1; i >= 0; i--) {
        const day = daysInPrevMonth - i;
        const dateStr = new Date(year, month - 1, day).toISOString().split('T')[0];
        html += `<div class="mini-cal-date other-month" onclick="changeDate('${dateStr}')">${day}</div>`;
    }
    
    // 当月日期
    for (let day = 1; day <= daysInMonth; day++) {
        const dateStr = new Date(year, month, day).toISOString().split('T')[0];
        const isToday = dateStr === today;
        const isSelected = dateStr === currentDate;
        const dayTasks = Storage.getTasks(dateStr);
        const hasTasks = dayTasks.length > 0;
        const allCompleted = hasTasks && dayTasks.every(t => t.completed);
        
        let className = 'mini-cal-date';
        if (isToday) className += ' today';
        if (isSelected) className += ' selected';
        if (hasTasks) className += allCompleted ? ' all-done' : ' has-tasks';
        
        html += `<div class="${className}" onclick="changeDate('${dateStr}')">${day}</div>`;
    }
    
    // 下月日期
    const remainingCells = 42 - (firstDay + daysInMonth);
    for (let day = 1; day <= remainingCells; day++) {
        const dateStr = new Date(year, month + 1, day).toISOString().split('T')[0];
        html += `<div class="mini-cal-date other-month" onclick="changeDate('${dateStr}')">${day}</div>`;
    }
    
    html += '</div>';
    container.innerHTML = html;
}

// ===== 渲染任务 =====
function formatTimeRange(task) {
    if (task.endTime) {
        return `${task.time} - ${task.endTime}`;
    }
    return task.time;
}

function getTagHtml(tag) {
    if (!tag) return '';
    const color = tagColors[tag] || tagColors['默认'];
    return `<span class="task-tag" style="background: ${color}20; color: ${color}; border: 1px solid ${color}40;">${tag}</span>`;
}

async function renderStandardTasks() {
    const container = document.getElementById('task-list');
    const empty = document.getElementById('empty-state');
    const settings = Storage.getSettings();
    const childMode = settings.childMode || {};
    
    if (!container) return;
    
    if (tasks.length === 0) {
        container.innerHTML = '';
        if (empty) empty.style.display = 'flex';
        return;
    }
    
    if (empty) empty.style.display = 'none';
    
    const sorted = [...tasks].sort((a, b) => a.time.localeCompare(b.time));
    const now = new Date();
    const isToday = currentDate === new Date().toISOString().split('T')[0];
    const currentTime = isToday ? `${String(now.getHours()).padStart(2, '0')}:${String(now.getMinutes()).padStart(2, '0')}` : '99:99';
    let activeFound = false;
    
    // 儿童模式且启用大卡片：使用图片任务卡布局
    if (childMode.enabled && childMode.largeCards) {
        container.className = 'visual-task-grid';
        container.innerHTML = '';
        
        for (const task of sorted) {
            const isActive = !task.completed && !activeFound && task.time >= currentTime;
            if (isActive) {
                activeFound = true;
                selectedTaskId = task.id;
            }
            await renderVisualTaskCardToContainer(task, container, isActive);
        }
        return;
    }
    
    // 标准模式：使用列表布局
    container.className = '';
    container.innerHTML = sorted.map(task => {
        const isActive = !task.completed && !activeFound && task.time >= currentTime;
        if (isActive) {
            activeFound = true;
            selectedTaskId = task.id;
        }
        
        const iconHtml = task.icon ? `<div class="task-icon">${task.icon}</div>` : '';
        const timeDisplay = formatTimeRange(task);
        const tagHtml = getTagHtml(task.tag);
        const repeatHtml = task.repeat ? `<span class="task-repeat" title="重复: ${getRepeatLabel(task.repeat)}">↻</span>` : '';
        const remindHtml = task.remind ? `<span class="task-remind" title="提前${task.remind}分钟提醒">⏰</span>` : '';
        
        // 获取颜色编码样式
        const colorStyle = getTaskColorStyle(task);
        
        return `
            <div class="task-item ${task.completed ? 'completed' : ''} ${isActive ? 'active' : ''} ${task.endTime ? 'has-range' : ''}" 
                 data-id="${task.id}"
                 onclick="selectTask('${task.id}')"
                 style="${colorStyle}">
                <div class="task-checkbox" onclick="event.stopPropagation(); toggleComplete('${task.id}')"></div>
                ${iconHtml}
                <div class="task-content">
                    <div class="task-name">${escapeHtml(task.name)} ${tagHtml} ${repeatHtml} ${remindHtml}</div>
                    <div class="task-time">${timeDisplay}</div>
                </div>
                <div class="task-actions">
                    <button class="task-edit" onclick="event.stopPropagation(); editTask('${task.id}')">
                        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path>
                            <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path>
                        </svg>
                    </button>
                    <button class="task-delete" onclick="event.stopPropagation(); deleteTask('${task.id}')">
                        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <polyline points="3 6 5 6 21 6"></polyline>
                            <path d="M19 6v14a2 2 0 01-2 2H7a2 2 0 01-2-2V6m3 0V4a2 2 0 012-2h4a2 2 0 012 2v2"></path>
                        </svg>
                    </button>
                </div>
            </div>
        `;
    }).join('');
}

async function renderSimpleTasks() {
    const container = document.getElementById('simple-task-list');
    const empty = document.getElementById('simple-empty');
    const settings = Storage.getSettings();
    const childMode = settings.childMode || {};
    
    if (!container) return;
    
    if (tasks.length === 0) {
        container.innerHTML = '';
        if (empty) empty.style.display = 'block';
        return;
    }
    
    if (empty) empty.style.display = 'none';
    
    const sorted = [...tasks].sort((a, b) => a.time.localeCompare(b.time));
    const now = new Date();
    const isToday = currentDate === new Date().toISOString().split('T')[0];
    const currentTime = isToday ? `${String(now.getHours()).padStart(2, '0')}:${String(now.getMinutes()).padStart(2, '0')}` : '99:99';
    let activeFound = false;
    
    // 儿童模式且启用大图片卡片：使用视觉任务卡
    if (childMode.enabled && childMode.showImages && childMode.largeCards) {
        container.className = 'visual-task-grid';
        container.innerHTML = '';
        
        for (const task of sorted) {
            const isActive = !task.completed && !activeFound && task.time >= currentTime;
            if (isActive) {
                activeFound = true;
                selectedTaskId = task.id;
            }
            await renderVisualTaskCardToContainer(task, container, isActive);
        }
        return;
    }
    
    // 标准简化模式
    container.className = '';
    
    // 并行获取所有任务的图片
    const tasksWithImages = await Promise.all(
        sorted.map(async (task) => {
            const imageData = task.image ? await getTaskImage(task.image) : null;
            return { ...task, imageData };
        })
    );
    
    container.innerHTML = tasksWithImages.map(task => {
        const isActive = !task.completed && !activeFound && task.time >= currentTime;
        if (isActive) activeFound = true;
        
        const timeDisplay = formatTimeRange(task);
        const tagHtml = getTagHtml(task.tag);
        
        // 获取颜色编码样式
        const colorStyle = getTaskColorStyle(task);
        const color = getTaskColor(task);
        const colorBorder = color ? `border-left: 6px solid ${color};` : '';
        
        // 如果有图片且儿童模式启用了图片显示
        if (task.imageData && childMode.showImages) {
            return `
                <div class="simple-task visual-simple-task ${task.completed ? 'done' : ''} ${isActive ? 'current' : ''}" 
                     style="${colorBorder} padding: 0; overflow: hidden;"
                     onclick="toggleComplete('${task.id}')">
                    <img src="${task.imageData}" style="width: 100%; height: 140px; object-fit: cover; display: block;">
                    <div style="padding: 16px;">
                        <div style="font-size: 20px; font-weight: 600; margin-bottom: 8px;">${escapeHtml(task.name)}</div>
                        <div style="color: var(--text-secondary); font-size: 16px;">🕐 ${timeDisplay}</div>
                    </div>
                </div>
            `;
        }
        
        return `
            <div class="simple-task ${task.completed ? 'done' : ''} ${isActive ? 'current' : ''} ${task.endTime ? 'has-range' : ''}"
                 style="${colorStyle}"
                 onclick="toggleComplete('${task.id}')">
                <div class="simple-checkbox"></div>
                <div class="simple-task-content">
                    <div class="simple-task-time">${timeDisplay} ${tagHtml}</div>
                    <div class="simple-task-text">${task.icon ? task.icon + ' ' : ''}${escapeHtml(task.name)}</div>
                </div>
            </div>
        `;
    }).join('');
}

function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

function selectTask(id) {
    document.querySelectorAll('.task-item').forEach(el => el.classList.remove('selected'));
    const el = document.querySelector(`.task-item[data-id="${id}"]`);
    if (el) {
        el.classList.add('selected');
        selectedTaskId = id;
    }
}

async function toggleComplete(id) {
    const task = tasks.find(t => t.id === id);
    if (!task) return;
    
    task.completed = !task.completed;
    Storage.saveTasks(currentDate, tasks);
    await updateAllViews();
    
    // 同步到 iOS 小组件
    if (window.xingxuNative && window.xingxuNative.ready) {
        window.xingxuNative.postMessage({ action: 'syncTasks' });
    }
    
    showToast(task.completed ? '任务已完成' : '任务已恢复');
}

async function deleteTask(id) {
    if (!confirm('确定删除此任务？')) return;
    
    // 如果是重复任务，询问是否删除整个系列
    const task = tasks.find(t => t.id === id);
    if (task && task.repeat && task.repeat !== 'none') {
        const deleteSeries = confirm('这是一个重复任务。\n点击"确定"删除整个系列，点击"取消"只删除当前日期的任务。');
        if (deleteSeries) {
            // 删除所有相关的重复任务
            const allTasks = Storage.getAllTasks();
            const parentId = task.parentId || task.id;
            const filtered = allTasks.filter(t => t.parentId !== parentId && t.id !== parentId);
            localStorage.setItem(Storage.key, JSON.stringify(filtered));
            tasks = Storage.getTasks(currentDate);
            await updateAllViews();
            showToast('已删除整个系列');
            return;
        }
    }
    
    tasks = tasks.filter(t => t.id !== id);
    Storage.saveTasks(currentDate, tasks);
    await updateAllViews();
    
    // 同步到 iOS 小组件
    if (window.xingxuNative && window.xingxuNative.ready) {
        window.xingxuNative.postMessage({ action: 'syncTasks' });
    }
    
    showToast('已删除');
}

// ===== 编辑任务 =====
function editTask(id) {
    const task = tasks.find(t => t.id === id);
    if (!task) return;
    
    document.getElementById('edit-name').value = task.name;
    document.getElementById('edit-time').value = task.time;
    document.getElementById('edit-end-time').value = task.endTime || '';
    document.getElementById('edit-icon').value = task.icon || '';
    document.getElementById('edit-tag').value = task.tag || '';
    document.getElementById('edit-repeat').value = task.repeat || 'none';
    document.getElementById('edit-remind').value = task.remind || '';
    document.getElementById('edit-task-id').value = id;
    
    // 渲染标签选项
    renderTagOptions('edit-tag');
    
    document.getElementById('edit-modal').classList.remove('hidden');
}

async function saveEdit() {
    const id = document.getElementById('edit-task-id').value;
    const name = document.getElementById('edit-name').value.trim();
    const time = document.getElementById('edit-time').value;
    const endTime = document.getElementById('edit-end-time').value;
    const icon = document.getElementById('edit-icon').value;
    const tag = document.getElementById('edit-tag').value;
    const repeat = document.getElementById('edit-repeat').value;
    const remind = document.getElementById('edit-remind').value;
    
    if (!name || !time) {
        showToast('请填写完整信息');
        return;
    }
    
    const task = tasks.find(t => t.id === id);
    if (task) {
        const oldRepeat = task.repeat;
        task.name = name;
        task.time = time;
        task.endTime = endTime || '';
        task.icon = icon;
        task.tag = tag;
        task.repeat = repeat;
        task.remind = remind ? parseInt(remind) : '';
        
        Storage.saveTasks(currentDate, tasks);
        
        // 如果重复规则改变，重新生成重复任务
        if (repeat !== oldRepeat && repeat !== 'none') {
            generateRepeatingTasks(task);
        }
        
        await updateAllViews();
        closeEditModal();
        showToast('任务已更新');
    }
}

function closeEditModal() {
    document.getElementById('edit-modal').classList.add('hidden');
}

// ===== 添加任务 =====
function showAddForm() {
    const input = document.getElementById('quick-name');
    if (input) input.focus();
}

function quickAddTask() {
    const name = document.getElementById('quick-name')?.value.trim();
    const time = document.getElementById('quick-time')?.value;
    const endTime = document.getElementById('quick-end-time')?.value;
    const icon = document.getElementById('quick-icon')?.value;
    const tag = document.getElementById('quick-tag')?.value;
    const repeat = document.getElementById('quick-repeat')?.value || 'none';
    const remind = document.getElementById('quick-remind')?.value;
    
    if (!name || !time) {
        showToast('请填写完整信息');
        return;
    }
    
    const image = document.getElementById('add-image')?.value || '';
    addTask(name, time, icon || '', endTime || '', tag, repeat, remind ? parseInt(remind) : '', image);
    document.getElementById('quick-name').value = '';
    document.getElementById('quick-end-time').value = '';
}

function simpleAddTask() {
    const name = document.getElementById('simple-input')?.value.trim();
    const time = document.getElementById('simple-time')?.value;
    const endTime = document.getElementById('simple-end-time')?.value;
    const tag = document.getElementById('simple-tag')?.value;
    
    if (!name || !time) {
        showToast('请填写完整信息');
        return;
    }
    
    addTask(name, time, '', endTime || '', tag, 'none', '', '');
    document.getElementById('simple-input').value = '';
    document.getElementById('simple-end-time').value = '';
}

async function addTask(name, time, icon, endTime, tag, repeat, remind, image = '') {
    const task = {
        id: Date.now().toString(),
        name,
        time,
        icon,
        endTime: endTime || '',
        completed: false,
        date: currentDate,
        tag: tag || '',
        repeat: repeat || 'none',
        remind: remind || '',
        image: image || ''
    };
    
    tasks.push(task);
    Storage.saveTasks(currentDate, tasks);
    
    // 如果是重复任务，生成后续任务
    if (repeat && repeat !== 'none') {
        generateRepeatingTasks(task);
    }
    
    await updateAllViews();
    showToast('任务已添加');
    
    // 请求通知权限并设置提醒
    if (remind && settings.notifications) {
        requestNotificationPermission().then(granted => {
            if (granted) {
                scheduleNotification(task);
            }
        });
    }
}

// ===== 重复任务功能 =====
function getRepeatLabel(repeat) {
    const labels = {
        'none': '不重复',
        'daily': '每天',
        'weekly': '每周',
        'workdays': '工作日',
        'weekends': '周末',
        'monthly': '每月'
    };
    return labels[repeat] || repeat;
}

function generateRepeatingTasks(parentTask, count = 30) {
    if (!parentTask.repeat || parentTask.repeat === 'none') return;
    
    const allTasks = Storage.getAllTasks();
    const parentId = parentTask.id;
    const baseDate = new Date(parentTask.date);
    
    for (let i = 1; i <= count; i++) {
        let nextDate = new Date(baseDate);
        
        switch (parentTask.repeat) {
            case 'daily':
                nextDate.setDate(baseDate.getDate() + i);
                break;
            case 'weekly':
                nextDate.setDate(baseDate.getDate() + i * 7);
                break;
            case 'workdays':
                // 只在周一到周五生成
                let workDaysAdded = 0;
                let daysToAdd = 0;
                while (workDaysAdded < i) {
                    daysToAdd++;
                    const testDate = new Date(baseDate);
                    testDate.setDate(baseDate.getDate() + daysToAdd);
                    const dayOfWeek = testDate.getDay();
                    if (dayOfWeek !== 0 && dayOfWeek !== 6) {
                        workDaysAdded++;
                    }
                }
                nextDate.setDate(baseDate.getDate() + daysToAdd);
                break;
            case 'weekends':
                // 只在周六和周日生成
                let weekendDaysAdded = 0;
                let weekendDaysToAdd = 0;
                while (weekendDaysAdded < i) {
                    weekendDaysToAdd++;
                    const testDate = new Date(baseDate);
                    testDate.setDate(baseDate.getDate() + weekendDaysToAdd);
                    const dayOfWeek = testDate.getDay();
                    if (dayOfWeek === 0 || dayOfWeek === 6) {
                        weekendDaysAdded++;
                    }
                }
                nextDate.setDate(baseDate.getDate() + weekendDaysToAdd);
                break;
            case 'monthly':
                nextDate.setMonth(baseDate.getMonth() + i);
                break;
            default:
                continue;
        }
        
        const dateStr = nextDate.toISOString().split('T')[0];
        
        // 检查该日期是否已有相同任务
        const exists = allTasks.some(t => 
            t.parentId === parentId && t.date === dateStr
        );
        
        if (!exists) {
            const childTask = {
                ...parentTask,
                id: Date.now().toString() + '-' + i,
                date: dateStr,
                parentId: parentId,
                completed: false
            };
            allTasks.push(childTask);
        }
    }
    
    localStorage.setItem(Storage.key, JSON.stringify(allTasks));
}

function checkAndGenerateRepeatingTasks() {
    // 定期检查是否需要生成更多重复任务
    const allTasks = Storage.getAllTasks();
    const repeatingTasks = allTasks.filter(t => t.repeat && t.repeat !== 'none' && !t.parentId);
    
    repeatingTasks.forEach(task => {
        const childTasks = allTasks.filter(t => t.parentId === task.id);
        const lastChild = childTasks.sort((a, b) => b.date.localeCompare(a.date))[0];
        
        if (lastChild) {
            const lastDate = new Date(lastChild.date);
            const today = new Date();
            const daysDiff = Math.floor((today - lastDate) / (1000 * 60 * 60 * 24));
            
            // 如果最后一个任务已经过去，生成更多
            if (daysDiff > 0) {
                generateRepeatingTasks(task, 30);
            }
        }
    });
}

// ===== 提醒通知功能 =====
async function requestNotificationPermission() {
    if (!('Notification' in window)) {
        return false;
    }
    
    if (Notification.permission === 'granted') {
        return true;
    }
    
    if (Notification.permission === 'denied') {
        return false;
    }
    
    const permission = await Notification.requestPermission();
    return permission === 'granted';
}

function setupNotification() {
    // 每分钟检查一次即将开始的任务
    setInterval(checkUpcomingTasks, 60000);
    // 立即检查一次
    checkUpcomingTasks();
}

function checkUpcomingTasks() {
    if (!settings.notifications || Notification.permission !== 'granted') return;
    
    const now = new Date();
    const todayStr = now.toISOString().split('T')[0];
    const todayTasks = Storage.getTasks(todayStr);
    
    todayTasks.forEach(task => {
        if (task.completed || !task.remind) return;
        
        const [hours, minutes] = task.time.split(':').map(Number);
        const taskTime = new Date(now);
        taskTime.setHours(hours, minutes, 0, 0);
        
        const remindTime = new Date(taskTime);
        remindTime.setMinutes(remindTime.getMinutes() - task.remind);
        
        const diff = now - remindTime;
        // 如果在提醒时间的1分钟内
        if (diff >= 0 && diff < 60000) {
            showNotification(task);
        }
    });
}

function scheduleNotification(task) {
    // 这个函数用于精确调度，但由于浏览器限制，我们使用轮询方式
    // 这里可以扩展使用 Service Worker 来实现更精确的提醒
}

function showNotification(task) {
    const notification = new Notification('星序 - 任务提醒', {
        body: `任务 "${task.name}" 将在 ${task.remind} 分钟后开始`,
        icon: '/favicon.ico',
        badge: '/favicon.ico',
        tag: task.id,
        requireInteraction: true
    });
    
    notification.onclick = () => {
        window.focus();
        notification.close();
    };
}

// ===== 备份状态 & 离线提醒 =====
function renderBackupStatus() {
    const container = document.getElementById('backup-status');
    if (!container) return;
    
    const lastBackup = localStorage.getItem(Storage.backupKey);
    const now = Date.now();
    const oneDay = 24 * 60 * 60 * 1000;
    const oneWeek = 7 * oneDay;
    
    if (!lastBackup) {
        container.style.display = 'block';
        container.style.background = 'rgba(239, 68, 68, 0.1)';
        container.style.color = '#EF4444';
        container.innerHTML = '⚠️ 尚未备份过数据。建议定期导出备份，避免数据丢失。';
        return;
    }
    
    const diff = now - parseInt(lastBackup);
    const days = Math.floor(diff / oneDay);
    
    if (days >= 7) {
        container.style.display = 'block';
        container.style.background = 'rgba(239, 68, 68, 0.1)';
        container.style.color = '#EF4444';
        container.innerHTML = `⚠️ 上次备份已是 ${days} 天前，建议立即导出备份。`;
    } else if (days >= 3) {
        container.style.display = 'block';
        container.style.background = 'rgba(245, 158, 11, 0.1)';
        container.style.color = '#D97706';
        container.innerHTML = `⏰ 上次备份是 ${days} 天前，建议定期备份数据。`;
    } else {
        container.style.display = 'block';
        container.style.background = 'rgba(16, 185, 129, 0.1)';
        container.style.color = '#059669';
        container.innerHTML = `✅ 数据已保护，${days === 0 ? '今天' : days + '天前'}备份过。`;
    }
}

function checkBackupReminder() {
    const lastBackup = localStorage.getItem(Storage.backupKey);
    const oneWeek = 7 * 24 * 60 * 60 * 1000;
    
    if (!lastBackup || (Date.now() - parseInt(lastBackup)) > oneWeek) {
        setTimeout(() => {
            showToast('💾 离线提示：建议定期导出数据备份');
        }, 3000);
    }
}

// ===== 设置 =====
function toggleSettings() {
    document.getElementById('settings-modal').classList.remove('hidden');
    loadSettings();
}

function closeSettings() {
    document.getElementById('settings-modal').classList.add('hidden');
}

function loadSettings() {
    document.getElementById('setting-notifications').checked = settings.notifications;
    document.getElementById('setting-remind-minutes').value = settings.notificationMinutes || 5;
    
    // 加载儿童模式和高对比度等视觉设置
    loadChildModeSettings();
    
    // 加载备份状态
    renderBackupStatus();
}

function saveSettings() {
    settings.notifications = document.getElementById('setting-notifications').checked;
    settings.notificationMinutes = parseInt(document.getElementById('setting-remind-minutes').value) || 5;
    
    Storage.saveSettings(settings);
    
    if (settings.notifications) {
        requestNotificationPermission();
    }
    
    closeSettings();
    showToast('设置已保存');
}

// ===== 清空和导出 =====
async function clearAllTasks() {
    if (!confirm('确定清空今日所有任务？')) return;
    
    tasks = [];
    Storage.saveTasks(currentDate, tasks);
    await updateAllViews();
    closeSettings();
    showToast('已清空所有任务');
}

async function clearDateRange() {
    const startDate = prompt('请输入开始日期 (YYYY-MM-DD):', currentDate);
    if (!startDate) return;
    
    const endDate = prompt('请输入结束日期 (YYYY-MM-DD):', currentDate);
    if (!endDate) return;
    
    if (!confirm(`确定清空 ${startDate} 到 ${endDate} 的所有任务？`)) return;
    
    const allTasks = Storage.getAllTasks();
    const filtered = allTasks.filter(t => t.date < startDate || t.date > endDate);
    localStorage.setItem(Storage.key, JSON.stringify(filtered));
    
    tasks = Storage.getTasks(currentDate);
    await updateAllViews();
    closeSettings();
    showToast('已清空指定范围的任务');
}

function exportData() {
    const option = confirm('点击"确定"导出所有数据，点击"取消"导出当前日期数据。');
    if (option) {
        Storage.export();
    } else {
        const blob = new Blob([JSON.stringify(tasks, null, 2)], { type: 'application/json' });
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `schedule-${currentDate}.json`;
        a.click();
        URL.revokeObjectURL(url);
        localStorage.setItem(Storage.backupKey, Date.now().toString());
    }
    showToast('数据已导出');
    renderBackupStatus();
}

function exportRange() {
    const startDate = prompt('请输入开始日期 (YYYY-MM-DD):', currentDate);
    if (!startDate) return;
    
    const endDate = prompt('请输入结束日期 (YYYY-MM-DD):', currentDate);
    if (!endDate) return;
    
    Storage.exportRange(startDate, endDate);
    showToast('数据已导出');
    renderBackupStatus();
}

// ===== 导入功能 =====
function openImportModal() {
    document.getElementById('import-modal').classList.remove('hidden');
    resetImport();
}

function closeImportModal() {
    document.getElementById('import-modal').classList.add('hidden');
}

function resetImport() {
    detectedTasks = [];
    document.getElementById('text-input').value = '';
    document.getElementById('import-input').classList.remove('hidden');
    document.getElementById('import-preview').classList.add('hidden');
}

function parseTextInput() {
    const text = document.getElementById('text-input').value.trim();
    
    if (!text) {
        showToast('请输入文字内容');
        return;
    }
    
    detectedTasks = parseTextToTasks(text);
    
    if (detectedTasks.length === 0) {
        showToast('未识别到有效任务，请检查时间格式');
        return;
    }
    
    showImportPreview();
}

function parseTimeStr(str) {
    const patterns = [
        /(\d{1,2})[:\：\.](\d{2})/,
        /(\d{1,2})\s*[点时]\s*(\d{0,2})\s*[分]?/,
        /(上午|下午|晚上|早上|am|pm)\s*(\d{1,2})[:\：\.\s]*(\d{0,2})/i
    ];
    
    for (const pattern of patterns) {
        const match = str.match(pattern);
        if (match) {
            let hour, minute = 0;
            const matchedText = match[0];
            
            if (/上午|早上|am/i.test(matchedText)) {
                hour = parseInt(match[2]);
            } else if (/下午|晚上|pm/i.test(matchedText)) {
                hour = parseInt(match[2]);
                if (hour < 12) hour += 12;
            } else if (matchedText.includes('点')) {
                hour = parseInt(match[1]);
                minute = parseInt(match[2] || 0);
            } else {
                hour = parseInt(match[1]);
                minute = parseInt(match[2]);
            }
            
            if (hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59) {
                return {
                    time: `${String(hour).padStart(2, '0')}:${String(minute).padStart(2, '0')}`,
                    matchedText: matchedText
                };
            }
        }
    }
    return null;
}

function parseTextToTasks(text) {
    const parsedTasks = [];
    const lines = text.split('\n').filter(l => l.trim());
    
    lines.forEach((line, idx) => {
        let time = null;
        let endTime = null;
        let name = line.trim();
        let tag = '';
        
        // 尝试匹配标签 [标签名]
        const tagMatch = line.match(/\[(.+?)\]/);
        if (tagMatch) {
            tag = tagMatch[1];
            name = name.replace(tagMatch[0], '').trim();
        }
        
        // 匹配时间段格式
        const rangePatterns = [
            /(\d{1,2}[:：.]\d{2}|\d{1,2}\s*点\s*\d{0,2}\s*分?|\d{1,2}\s*点)\s*[\-~—到至]\s*(\d{1,2}[:：.]\d{2}|\d{1,2}\s*点\s*\d{0,2}\s*分?|\d{1,2}\s*点)/,
            /(上午|下午|晚上|早上|am|pm)?\s*(\d{1,2})\s*[:：.点]?\s*(\d{0,2})?\s*分?\s*[\-~—到至]\s*(上午|下午|晚上|早上|am|pm)?\s*(\d{1,2})\s*[:：.点]?\s*(\d{0,2})?\s*分?/i
        ];
        
        let rangeMatched = false;
        for (const pattern of rangePatterns) {
            const match = line.match(pattern);
            if (match) {
                const fullMatch = match[0];
                const parts = fullMatch.split(/[\-~—到至]/);
                if (parts.length >= 2) {
                    const startResult = parseTimeStr(parts[0]);
                    const endResult = parseTimeStr(parts[1]);
                    
                    if (startResult && endResult) {
                        time = startResult.time;
                        endTime = endResult.time;
                        name = line.replace(fullMatch, '').replace(/\[.+?\]/, '').trim();
                        rangeMatched = true;
                        break;
                    }
                }
            }
        }
        
        if (!rangeMatched) {
            const result = parseTimeStr(line);
            if (result) {
                time = result.time;
                name = line.replace(result.matchedText, '').replace(/\[.+?\]/, '').trim();
            }
        }
        
        name = name.replace(/^[\d\.\、\-\—\:\s,，]+/, '').trim();
        
        if (name && name.length > 1) {
            parsedTasks.push({
                id: 'import-' + idx,
                name: name.slice(0, 100),
                time: time || '09:00',
                endTime: endTime || '',
                tag: tag,
                selected: true
            });
        }
    });
    
    return parsedTasks.slice(0, 50);
}

function showImportPreview() {
    const container = document.getElementById('detected-list');
    
    container.innerHTML = detectedTasks.map((task, idx) => {
        const timeDisplay = task.endTime ? `${task.time} - ${task.endTime}` : task.time;
        const tagHtml = task.tag ? `<span class="detected-tag">[${escapeHtml(task.tag)}]</span>` : '';
        return `
        <div class="detected-item">
            <input type="checkbox" id="import-${idx}" checked onchange="detectedTasks[${idx}].selected = this.checked">
            <div class="detected-task-info">
                <div class="detected-task-name">${escapeHtml(task.name)} ${tagHtml}</div>
                <div class="detected-task-time">${timeDisplay}</div>
            </div>
        </div>
    `}).join('');
    
    document.getElementById('import-input').classList.add('hidden');
    document.getElementById('import-preview').classList.remove('hidden');
}

async function confirmImport() {
    const toImport = detectedTasks.filter(t => t.selected);
    
    if (toImport.length === 0) {
        showToast('未选择任何任务');
        return;
    }
    
    toImport.forEach(t => {
        const task = {
            id: Date.now().toString() + Math.random().toString(36).substr(2, 5),
            name: t.name,
            time: t.time,
            endTime: t.endTime || '',
            icon: '',
            completed: false,
            date: currentDate,
            tag: t.tag || '',
            repeat: 'none',
            remind: ''
        };
        tasks.push(task);
    });
    
    Storage.saveTasks(currentDate, tasks);
    await updateAllViews();
    closeImportModal();
    showToast(`已导入 ${toImport.length} 个任务`);
}

// ===== 文件导入 =====
function handleFileImport(event) {
    const file = event.target.files[0];
    if (!file) return;
    
    const reader = new FileReader();
    reader.onload = async (e) => {
        const result = Storage.import(e.target.result);
        if (result.success) {
            tasks = Storage.getTasks(currentDate);
            await updateAllViews();
            showToast(`成功导入 ${result.count} 个任务`);
        } else {
            showToast('导入失败: ' + result.error);
        }
    };
    reader.readAsText(file);
}

// ===== 标签功能 =====
function renderTagOptions(selectId) {
    const select = document.getElementById(selectId);
    if (!select) return;
    
    const currentValue = select.value;
    select.innerHTML = '<option value="">无标签</option>';
    
    settings.defaultTags.forEach(tag => {
        const option = document.createElement('option');
        option.value = tag;
        option.textContent = tag;
        select.appendChild(option);
    });
    
    select.value = currentValue;
}

function addCustomTag() {
    const input = document.getElementById('custom-tag-input');
    const tag = input.value.trim();
    
    if (!tag) return;
    if (settings.defaultTags.includes(tag)) {
        showToast('标签已存在');
        return;
    }
    
    settings.defaultTags.push(tag);
    Storage.saveSettings(settings);
    
    renderTagOptions('quick-tag');
    renderTagOptions('edit-tag');
    renderTagOptions('simple-tag');
    
    input.value = '';
    showToast('标签已添加');
}

// ===== 键盘 =====
function setupKeyboard() {
    document.addEventListener('keydown', (e) => {
        if (e.target.tagName === 'INPUT' || e.target.tagName === 'TEXTAREA' || e.target.tagName === 'SELECT') {
            if (e.key === 'Escape') e.target.blur();
            return;
        }
        
        switch (e.key.toLowerCase()) {
            case 'n':
                if (currentMode === 'standard') showAddForm();
                else document.getElementById('simple-input')?.focus();
                break;
            case ' ':
            case 'enter':
                if (selectedTaskId) {
                    e.preventDefault();
                    toggleComplete(selectedTaskId);
                }
                break;
            case 'delete':
            case 'backspace':
                if (selectedTaskId && currentMode === 'standard') {
                    deleteTask(selectedTaskId);
                }
                break;
            case 's':
                if (currentMode === 'standard') switchToSimple();
                else switchToStandard();
                break;
            case 'arrowleft':
                if (e.altKey) {
                    e.preventDefault();
                    goToPrevDay();
                }
                break;
            case 'arrowright':
                if (e.altKey) {
                    e.preventDefault();
                    goToNextDay();
                }
                break;
            case 't':
                if (e.altKey) {
                    e.preventDefault();
                    goToToday();
                }
                break;
            case 'escape':
                closeImportModal();
                closeSettings();
                break;
        }
    });
}

// ===== 工具 =====
function showToast(message) {
    const toast = document.getElementById('toast');
    toast.innerHTML = `<span>${message}</span>`;
    toast.classList.remove('hidden');
    
    setTimeout(() => {
        toast.classList.add('hidden');
    }, 2000);
}

// 点击外部关闭
window.onclick = function(e) {
    if (e.target.classList.contains('modal')) {
        e.target.classList.add('hidden');
    }
};

// 初始化标签选项
document.addEventListener('DOMContentLoaded', () => {
    renderTagOptions('quick-tag');
    renderTagOptions('simple-tag');
});


// ===== 图片任务卡功能 =====

// 图片存储（使用 IndexedDB 存储大图片）
const ImageStorage = {
    dbName: 'schedule-images',
    storeName: 'images',
    db: null,
    
    async init() {
        return new Promise((resolve, reject) => {
            const request = indexedDB.open(this.dbName, 1);
            request.onerror = () => reject(request.error);
            request.onsuccess = () => {
                this.db = request.result;
                resolve(this.db);
            };
            request.onupgradeneeded = (event) => {
                const db = event.target.result;
                if (!db.objectStoreNames.contains(this.storeName)) {
                    db.createObjectStore(this.storeName, { keyPath: 'id' });
                }
            };
        });
    },
    
    async saveImage(id, imageData) {
        if (!this.db) await this.init();
        return new Promise((resolve, reject) => {
            const transaction = this.db.transaction([this.storeName], 'readwrite');
            const store = transaction.objectStore(this.storeName);
            const request = store.put({ id, data: imageData, timestamp: Date.now() });
            request.onsuccess = () => resolve();
            request.onerror = () => reject(request.error);
        });
    },
    
    async getImage(id) {
        if (!this.db) await this.init();
        return new Promise((resolve, reject) => {
            const transaction = this.db.transaction([this.storeName], 'readonly');
            const store = transaction.objectStore(this.storeName);
            const request = store.get(id);
            request.onsuccess = () => resolve(request.result?.data || null);
            request.onerror = () => reject(request.error);
        });
    },
    
    async deleteImage(id) {
        if (!this.db) await this.init();
        return new Promise((resolve, reject) => {
            const transaction = this.db.transaction([this.storeName], 'readwrite');
            const store = transaction.objectStore(this.storeName);
            const request = store.delete(id);
            request.onsuccess = () => resolve();
            request.onerror = () => reject(request.error);
        });
    }
};

// 处理图片上传
async function handleTaskImageUpload(event) {
    const file = event.target.files[0];
    if (!file) return;
    
    // 验证文件类型
    if (!file.type.startsWith('image/')) {
        showToast('请选择图片文件');
        return;
    }
    
    // 验证文件大小（最大 5MB）
    if (file.size > 5 * 1024 * 1024) {
        showToast('图片大小不能超过 5MB');
        return;
    }
    
    try {
        const reader = new FileReader();
        reader.onload = async (e) => {
            const imageData = e.target.result;
            const imageId = 'img-' + Date.now();
            
            // 保存到 IndexedDB
            await ImageStorage.saveImage(imageId, imageData);
            
            // 更新预览
            const preview = document.getElementById('task-image-preview');
            const uploadArea = document.getElementById('task-image-upload');
            const removeBtn = uploadArea.querySelector('.image-remove-btn');
            const placeholder = uploadArea.querySelector('.image-upload-placeholder');
            
            preview.src = imageData;
            preview.classList.remove('hidden');
            preview.dataset.imageId = imageId;
            if (removeBtn) removeBtn.classList.remove('hidden');
            if (placeholder) placeholder.classList.add('hidden');
            
            // 保存到隐藏字段
            document.getElementById('add-image').value = imageId;
            
            showToast('图片已上传');
        };
        reader.readAsDataURL(file);
    } catch (error) {
        console.error('图片上传失败:', error);
        showToast('图片上传失败');
    }
}

// 移除任务图片
function removeTaskImage(event) {
    event.stopPropagation();
    
    const preview = document.getElementById('task-image-preview');
    const uploadArea = document.getElementById('task-image-upload');
    const removeBtn = uploadArea.querySelector('.image-remove-btn');
    const placeholder = uploadArea.querySelector('.image-upload-placeholder');
    const imageId = preview.dataset.imageId;
    
    // 从 IndexedDB 删除
    if (imageId) {
        ImageStorage.deleteImage(imageId);
    }
    
    // 重置预览
    preview.src = '';
    preview.classList.add('hidden');
    preview.dataset.imageId = '';
    if (removeBtn) removeBtn.classList.add('hidden');
    if (placeholder) placeholder.classList.remove('hidden');
    document.getElementById('add-image').value = '';
    document.getElementById('task-image-input').value = '';
}

// 获取任务图片
async function getTaskImage(imageId) {
    if (!imageId) return null;
    return await ImageStorage.getImage(imageId);
}

// ===== 颜色编码系统 =====

// 获取任务颜色编码
function getTaskColor(task) {
    const settings = Storage.getSettings();
    if (!settings.colorCoding || !settings.colorCoding.enabled) {
        return null;
    }
    
    const colors = settings.colorCoding;
    
    // 根据标签返回颜色
    if (task.tag) {
        switch (task.tag) {
            case '工作': return colors.work;
            case '学习': return colors.study;
            case '生活': return colors.life;
            case '健康': return colors.health;
            case '娱乐': return colors.entertainment;
            case '重要': return colors.important;
        }
    }
    
    // 根据时间段返回颜色
    if (task.time) {
        const hour = parseInt(task.time.split(':')[0]);
        if (hour >= 6 && hour < 12) return colors.morning;
        if (hour >= 12 && hour < 18) return colors.afternoon;
        if (hour >= 18 || hour < 6) return colors.evening;
    }
    
    return colors.default;
}

// 获取颜色边框样式
function getColorBorderStyle(color) {
    if (!color) return '';
    return `border-left: 4px solid ${color};`;
}

// 获取颜色背景样式（淡色）
function getColorBgStyle(color) {
    if (!color) return '';
    const hex = color.replace('#', '');
    const r = parseInt(hex.substr(0, 2), 16);
    const g = parseInt(hex.substr(2, 2), 16);
    const b = parseInt(hex.substr(4, 2), 16);
    return `background: rgba(${r}, ${g}, ${b}, 0.1);`;
}

// 渲染带颜色的任务项
function renderColoredTaskItem(task, isActive, isStandard = true) {
    const color = getTaskColor(task);
    const borderStyle = getColorBorderStyle(color);
    const bgStyle = getColorBgStyle(color);
    
    if (isStandard) {
        return `style="${borderStyle} ${bgStyle}"`;
    } else {
        return `style="${borderStyle}"`;
    }
}

// 获取任务颜色样式（用于内联样式）
function getTaskColorStyle(task) {
    const settings = Storage.getSettings();
    if (!settings.colorCoding || !settings.colorCoding.enabled) {
        return '';
    }
    
    const color = getTaskColor(task);
    if (!color) return '';
    
    // 返回边框样式
    return `border-left: 4px solid ${color};`;
}

// 渲染视觉任务卡到指定容器（用于儿童模式）
async function renderVisualTaskCardToContainer(task, container, isActive = false) {
    const imageData = task.image ? await getTaskImage(task.image) : null;
    const color = getTaskColor(task);
    const settings = Storage.getSettings();
    const childMode = settings.childMode || {};
    
    const card = document.createElement('div');
    card.className = `visual-task-card ${task.completed ? 'done' : ''} ${isActive ? 'active' : ''}`;
    if (color) {
        card.style.borderColor = color;
    }
    card.dataset.taskId = task.id;
    
    // 点击切换完成状态
    card.addEventListener('click', () => toggleComplete(task.id));
    
    let html = '';
    
    // 图片区域（如果启用了图片显示且有图片）
    if (imageData && childMode.showImages !== false) {
        html += `
            <div class="visual-task-image-wrapper">
                <img src="${imageData}" class="visual-task-image" alt="${escapeHtml(task.name)}">
            </div>
        `;
    }
    
    // 内容区域
    html += `
        <div class="visual-task-content">
            ${task.icon ? `<div class="visual-task-icon">${task.icon}</div>` : ''}
            <div class="visual-task-title">${escapeHtml(task.name)}</div>
            <div class="visual-task-time">
                <span>🕐</span>
                <span>${formatTimeRange(task)}</span>
            </div>
            ${task.completed ? '<div class="visual-task-complete-badge">✓ 完成</div>' : ''}
        </div>
    `;
    
    card.innerHTML = html;
    container.appendChild(card);
}

// ===== 儿童模式功能 =====

// 切换儿童模式
async function toggleChildMode(enabled) {
    const settings = Storage.getSettings();
    settings.childMode = settings.childMode || {};
    settings.childMode.enabled = enabled;
    Storage.saveSettings(settings);
    
    // 显示/隐藏详细选项
    const childModeOptions = document.getElementById('child-mode-options');
    if (childModeOptions) {
        childModeOptions.style.display = enabled ? 'block' : 'none';
    }
    
    if (enabled) {
        document.body.classList.add('child-mode');
        applyChildModeStyles();
    } else {
        document.body.classList.remove('child-mode');
        removeChildModeStyles();
    }
    
    await updateAllViews();
}

// 应用儿童模式样式
function applyChildModeStyles() {
    const settings = Storage.getSettings();
    const childMode = settings.childMode || {};
    
    // 设置大字体
    if (childMode.fontSize === 'large') {
        document.documentElement.style.fontSize = '18px';
    } else if (childMode.fontSize === 'extra-large') {
        document.documentElement.style.fontSize = '22px';
    }
    
    // 设置高对比度
    if (childMode.highContrast) {
        document.body.setAttribute('data-theme', 'high-contrast');
    }
}

// 移除儿童模式样式
function removeChildModeStyles() {
    document.documentElement.style.fontSize = '';
    const settings = Storage.getSettings();
    if (settings.theme && settings.theme !== 'high-contrast') {
        document.body.setAttribute('data-theme', settings.theme);
    }
}

// 渲染图片任务卡（儿童模式）
async function renderVisualTaskCard(task, container) {
    const imageData = task.image ? await getTaskImage(task.image) : null;
    const color = getTaskColor(task);
    const colorStyle = color ? `border-color: ${color};` : '';
    
    const card = document.createElement('div');
    card.className = `visual-task-card ${task.completed ? 'done' : ''}`;
    card.style = colorStyle;
    card.dataset.taskId = task.id;
    
    let html = '';
    
    // 图片区域
    if (imageData) {
        html += `
            <div class="visual-task-image-wrapper">
                <img src="${imageData}" class="visual-task-image" alt="${escapeHtml(task.name)}">
            </div>
        `;
    }
    
    // 内容区域
    html += `
        <div class="visual-task-content">
            ${task.icon ? `<div class="visual-task-icon">${task.icon}</div>` : ''}
            <div class="visual-task-title">${escapeHtml(task.name)}</div>
            <div class="visual-task-time">
                <span>🕐</span>
                <span>${formatTimeRange(task)}</span>
            </div>
            ${task.completed ? '<div class="visual-task-complete-badge">✓ 完成</div>' : ''}
        </div>
    `;
    
    card.innerHTML = html;
    
    // 点击切换完成状态
    card.addEventListener('click', () => toggleComplete(task.id));
    
    container.appendChild(card);
}

// 渲染简化版图片任务（适合小屏幕）
async function renderSimpleVisualTask(task) {
    const imageData = task.image ? await getTaskImage(task.image) : null;
    const color = getTaskColor(task);
    const colorBorder = color ? `border-left: 6px solid ${color};` : '';
    
    let html = '';
    
    if (imageData) {
        html += `
            <div class="simple-task visual-simple-task ${task.completed ? 'done' : ''}" 
                 style="${colorBorder} padding: 0; overflow: hidden;"
                 onclick="toggleComplete('${task.id}')">
                <img src="${imageData}" style="width: 100%; height: 140px; object-fit: cover; display: block;">
                <div style="padding: 16px;">
                    <div style="font-size: 20px; font-weight: 600; margin-bottom: 8px;">${escapeHtml(task.name)}</div>
                    <div style="color: var(--text-secondary); font-size: 16px;">🕐 ${formatTimeRange(task)}</div>
                </div>
            </div>
        `;
    } else {
        // 无图片时使用普通样式
        html = `
            <div class="simple-task ${task.completed ? 'done' : ''}" style="${colorBorder}" onclick="toggleComplete('${task.id}')">
                <div class="simple-checkbox"></div>
                <div class="simple-task-content">
                    <div class="simple-task-time">${formatTimeRange(task)}</div>
                    <div class="simple-task-text">${task.icon ? task.icon + ' ' : ''}${escapeHtml(task.name)}</div>
                </div>
            </div>
        `;
    }
    
    return html;
}

// ===== 大字体/高对比度模式 =====

// 设置字体大小
function setFontSize(size) {
    const sizes = {
        'normal': '14px',
        'large': '18px',
        'extra-large': '22px'
    };
    
    document.documentElement.style.fontSize = sizes[size] || sizes['normal'];
    
    // 保存设置
    const settings = Storage.getSettings();
    settings.fontSize = size;
    Storage.saveSettings(settings);
}

// 设置高对比度模式
function setHighContrast(enabled) {
    if (enabled) {
        document.body.setAttribute('data-theme', 'high-contrast');
    } else {
        const settings = Storage.getSettings();
        document.body.setAttribute('data-theme', settings.theme || 'light');
    }
    
    // 保存设置
    const settings = Storage.getSettings();
    settings.highContrast = enabled;
    Storage.saveSettings(settings);
}

// 切换颜色编码
async function toggleColorCoding(enabled) {
    const settings = Storage.getSettings();
    settings.colorCoding = settings.colorCoding || {};
    settings.colorCoding.enabled = enabled;
    Storage.saveSettings(settings);
    
    await updateAllViews();
}

// 保存儿童模式详细设置
async function saveChildModeSettings() {
    const settings = Storage.getSettings();
    settings.childMode = settings.childMode || {};
    
    // 获取所有儿童模式选项的状态
    settings.childMode.showWeather = document.getElementById('child-show-weather')?.checked ?? true;
    settings.childMode.showImages = document.getElementById('child-show-images')?.checked ?? true;
    settings.childMode.colorCoding = document.getElementById('child-color-coding')?.checked ?? true;
    settings.childMode.largeCards = document.getElementById('child-large-cards')?.checked ?? true;
    settings.childMode.voicePrompts = document.getElementById('child-voice-prompts')?.checked ?? true;
    
    Storage.saveSettings(settings);
    
    // 如果儿童模式已启用，立即应用更改
    if (settings.childMode.enabled) {
        await updateAllViews();
    }
}

// 加载儿童模式设置到UI
function loadChildModeSettings() {
    const settings = Storage.getSettings();
    const childMode = settings.childMode || {};
    
    // 设置复选框状态
    const childModeEnabled = document.getElementById('child-mode-enabled');
    if (childModeEnabled) {
        childModeEnabled.checked = childMode.enabled || false;
        // 显示/隐藏详细选项
        const childModeOptions = document.getElementById('child-mode-options');
        if (childModeOptions) {
            childModeOptions.style.display = childMode.enabled ? 'block' : 'none';
        }
    }
    
    const showWeather = document.getElementById('child-show-weather');
    if (showWeather) showWeather.checked = childMode.showWeather !== false;
    
    const showImages = document.getElementById('child-show-images');
    if (showImages) showImages.checked = childMode.showImages !== false;
    
    const colorCoding = document.getElementById('child-color-coding');
    if (colorCoding) colorCoding.checked = childMode.colorCoding !== false;
    
    const largeCards = document.getElementById('child-large-cards');
    if (largeCards) largeCards.checked = childMode.largeCards !== false;
    
    const voicePrompts = document.getElementById('child-voice-prompts');
    if (voicePrompts) voicePrompts.checked = childMode.voicePrompts !== false;
    
    // 设置颜色编码开关
    const colorCodingEnabled = document.getElementById('color-coding-enabled');
    if (colorCodingEnabled) {
        colorCodingEnabled.checked = settings.colorCoding?.enabled !== false;
    }
    
    // 设置高对比度开关
    const highContrastMode = document.getElementById('high-contrast-mode');
    if (highContrastMode) {
        highContrastMode.checked = settings.highContrast || false;
    }
    
    // 设置字体大小按钮
    const fontSize = settings.fontSize || 'normal';
    document.querySelectorAll('.font-size-selector button').forEach(btn => {
        btn.classList.remove('active');
    });
    const activeBtn = document.getElementById(`font-${fontSize}`);
    if (activeBtn) activeBtn.classList.add('active');
}

// 初始化视觉辅助功能
document.addEventListener('DOMContentLoaded', async () => {
    // 初始化图片存储
    ImageStorage.init().catch(console.error);
    
    // 应用保存的视觉设置
    const settings = Storage.getSettings();
    
    if (settings.fontSize) {
        setFontSize(settings.fontSize);
    }
    
    if (settings.highContrast) {
        setHighContrast(true);
    }
    
    if (settings.childMode && settings.childMode.enabled) {
        await toggleChildMode(true);
    }
});
