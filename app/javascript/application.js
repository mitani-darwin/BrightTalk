// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import * as ActiveStorage from "@rails/activestorage"
import "@hotwired/stimulus-loading"
import "controllers"

// Passkey module
import "passkey"

// ライブラリ読み込み状態管理
class LibraryManager {
    constructor() {
        this.loadedLibraries = new Map();
        this.loadingPromises = new Map();
        this.retryAttempts = new Map();
        this.maxRetries = 3;
        this.retryDelay = 1000; // 1秒
        this.loadTimeout = 10000; // 10秒
        this.dependencyOrder = [
            'Turbo', 'Stimulus', 'SparkMD5', 'CodeMirror', 'Video.js', 'Bootstrap'
        ];
        this.fallbackUrls = new Map([
            ['bootstrap', [
                'https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.esm.min.js',
                'https://unpkg.com/bootstrap@5.3.2/dist/js/bootstrap.esm.js'
            ]]
        ]);
    }

    // 読み込み状態チェック
    isLoaded(libraryName) {
        return this.loadedLibraries.get(libraryName) === 'loaded';
    }

    // 読み込み失敗状態チェック
    isFailed(libraryName) {
        return this.loadedLibraries.get(libraryName) === 'failed';
    }

    // リトライ機能付きライブラリ読み込み
    async loadWithRetry(libraryName, importFunction, maxRetries = this.maxRetries) {
        const attempts = this.retryAttempts.get(libraryName) || 0;
        
        if (attempts >= maxRetries) {
            console.warn(`${libraryName}: Maximum retry attempts (${maxRetries}) exceeded`);
            this.loadedLibraries.set(libraryName, 'failed');
            throw new Error(`Failed to load ${libraryName} after ${maxRetries} attempts`);
        }

        try {
            this.loadedLibraries.set(libraryName, 'loading');
            console.log(`${libraryName}: Loading attempt ${attempts + 1}/${maxRetries}`);
            
            // タイムアウト付きでライブラリ読み込み
            const module = await Promise.race([
                importFunction(),
                new Promise((_, reject) => 
                    setTimeout(() => reject(new Error('Load timeout')), this.loadTimeout)
                )
            ]);

            this.loadedLibraries.set(libraryName, 'loaded');
            this.retryAttempts.delete(libraryName);
            console.log(`${libraryName}: Loaded successfully on attempt ${attempts + 1}`);
            return module;

        } catch (error) {
            const newAttempts = attempts + 1;
            this.retryAttempts.set(libraryName, newAttempts);
            
            // より詳細なエラーログ
            if (error.message.includes('Importing binding name') || error.message.includes('not found')) {
                console.error(`${libraryName}: Named export error detected - ${error.message}`);
                console.error('This may indicate a CDN compatibility issue or incorrect module format');
            } else if (error.message.includes('Load timeout')) {
                console.warn(`${libraryName}: Timeout occurred after ${this.loadTimeout}ms`);
            } else {
                console.warn(`${libraryName}: Attempt ${newAttempts} failed:`, error.message);
            }

            if (newAttempts < maxRetries) {
                console.log(`${libraryName}: Retrying in ${this.retryDelay}ms...`);
                await new Promise(resolve => setTimeout(resolve, this.retryDelay));
                return this.loadWithRetry(libraryName, importFunction, maxRetries);
            } else {
                this.loadedLibraries.set(libraryName, 'failed');
                console.error(`${libraryName}: All ${maxRetries} attempts failed. Final error:`, error.message);
                throw error;
            }
        }
    }

    // 依存関係を考慮したライブラリ読み込み
    async loadLibraryWithDependencies(libraryConfig) {
        const { name, import: importFunc, dependencies = [], fallback = null } = libraryConfig;

        // 既に読み込み済みの場合はスキップ
        if (this.isLoaded(name)) {
            console.log(`${name}: Already loaded, skipping`);
            return window[name.toLowerCase()];
        }

        // 既に読み込み中の場合は待機
        if (this.loadingPromises.has(name)) {
            console.log(`${name}: Already loading, waiting...`);
            return this.loadingPromises.get(name);
        }

        const loadingPromise = this.performLibraryLoad(name, importFunc, dependencies, fallback);
        this.loadingPromises.set(name, loadingPromise);

        try {
            const result = await loadingPromise;
            this.loadingPromises.delete(name);
            return result;
        } catch (error) {
            this.loadingPromises.delete(name);
            throw error;
        }
    }

    async performLibraryLoad(name, importFunc, dependencies, fallback) {
        try {
            // 依存関係の確認
            for (const dep of dependencies) {
                if (!this.isLoaded(dep)) {
                    console.warn(`${name}: Dependency ${dep} is not loaded, may cause issues`);
                }
            }

            // メインURL試行
            let module;
            try {
                module = await this.loadWithRetry(name, importFunc);
            } catch (error) {
                // フォールバック試行
                if (fallback) {
                    console.warn(`${name}: Main load failed, trying fallback...`);
                    module = await this.loadWithRetry(`${name}-fallback`, fallback);
                } else {
                    throw error;
                }
            }

            // グローバル変数に設定
            const globalName = name.toLowerCase().replace(/[.-]/g, '');
            window[globalName] = module.default || module;

            // 特別な処理
            if (name === 'Turbo') {
                window.Turbo = module.default || module;
            }

            return module;

        } catch (error) {
            console.error(`${name}: Failed to load completely:`, error);
            throw error;
        }
    }

    // 読み込み状況レポート
    getLoadingReport() {
        const report = {
            loaded: [],
            failed: [],
            total: this.loadedLibraries.size
        };

        for (const [name, status] of this.loadedLibraries) {
            if (status === 'loaded') {
                report.loaded.push(name);
            } else if (status === 'failed') {
                report.failed.push(name);
            }
        }

        return report;
    }
}

// ライブラリマネージャーインスタンス作成
const libraryManager = new LibraryManager();

// 主要ライブラリの設定
const libraryConfigs = [
    {
        name: 'Turbo',
        import: () => import("@hotwired/turbo"),
        dependencies: []
    },
    {
        name: 'Stimulus', 
        import: () => import("@hotwired/stimulus"),
        dependencies: []
    },
    {
        name: 'SparkMD5',
        import: () => import("spark-md5"),
        dependencies: []
    },
    {
        name: 'CodeMirror',
        import: () => import("codemirror"),
        dependencies: []
    },
    {
        name: 'Video.js',
        import: () => import("video.js"),
        dependencies: []
    },
    {
        name: 'Bootstrap',
        import: () => import("bootstrap"),
        dependencies: [],
        fallback: () => import("https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.esm.min.js")
    }
];

// CodeMirrorモード設定
const codeMirrorModes = [
    'codemirror/mode/markdown/markdown',
    'codemirror/mode/javascript/javascript', 
    'codemirror/mode/xml/xml',
    'codemirror/mode/css/css'
];

// 改善された非同期ライブラリ読み込み関数
async function loadLibrariesAdvanced() {
    console.log('Starting advanced library loading...');
    const loadStart = Date.now();
    
    try {
        // 主要ライブラリの並列読み込み
        const loadResults = await Promise.allSettled(
            libraryConfigs.map(config => 
                libraryManager.loadLibraryWithDependencies(config)
                    .catch(error => ({
                        library: config.name,
                        error: error.message
                    }))
            )
        );

        // CodeMirror読み込み後にモード読み込み
        if (libraryManager.isLoaded('CodeMirror')) {
            console.log('Loading CodeMirror modes...');
            const modeResults = await Promise.allSettled(
                codeMirrorModes.map(mode => 
                    import(mode).catch(error => {
                        console.warn(`Failed to load CodeMirror mode ${mode}:`, error.message);
                        return null;
                    })
                )
            );
            
            const loadedModes = modeResults.filter(result => 
                result.status === 'fulfilled' && result.value !== null
            ).length;
            console.log(`CodeMirror modes loaded: ${loadedModes}/${codeMirrorModes.length}`);
        }

        // 特別な初期化処理
        await performSpecialInitialization();

        // 読み込み結果レポート
        const report = libraryManager.getLoadingReport();
        const loadEnd = Date.now();
        
        console.log('=== Library Loading Report ===');
        console.log(`Total time: ${loadEnd - loadStart}ms`);
        console.log(`Successfully loaded: ${report.loaded.length}/${report.total}`);
        console.log('✓ Loaded libraries:', report.loaded.join(', '));
        
        if (report.failed.length > 0) {
            console.warn('✗ Failed libraries:', report.failed.join(', '));
        }

        // グローバル変数状況確認
        console.log('=== Global Variable Status ===');
        const globalVars = ['Turbo', 'ActiveStorage', 'SparkMD5', 'CodeMirror', 'videojs', 'bootstrap'];
        globalVars.forEach(varName => {
            const exists = typeof window[varName.toLowerCase()] !== 'undefined';
            console.log(`- ${varName}:`, exists ? '✓ Available' : '✗ Missing');
        });

    } catch (error) {
        console.error('Critical error in library loading:', error);
    }
}

// 特別な初期化処理
async function performSpecialInitialization() {
    // Stimulus初期化
    if (libraryManager.isLoaded('Stimulus')) {
        try {
            const { Application } = await import("@hotwired/stimulus");
            if (!window.Stimulus) {
                window.Stimulus = { Application };
                console.log('Stimulus: Global application object configured');
            }
        } catch (error) {
            console.warn('Stimulus: Failed to configure application object:', error.message);
        }
    }
}

// Bootstrap機能の高度な初期化
function initializeBootstrapComponents() {
    if (!window.bootstrap) {
        console.warn('Bootstrap not available for component initialization');
        return;
    }

    try {
        console.log('Initializing Bootstrap components...');
        
        // ドロップダウン初期化
        const dropdowns = document.querySelectorAll('[data-bs-toggle="dropdown"]');
        dropdowns.forEach((element, index) => {
            try {
                if (!window.bootstrap.Dropdown.getInstance(element)) {
                    new window.bootstrap.Dropdown(element);
                    console.log(`Dropdown ${index + 1} initialized`);
                }
            } catch (error) {
                console.warn(`Failed to initialize dropdown ${index + 1}:`, error.message);
            }
        });

        // コラプス初期化
        const collapses = document.querySelectorAll('[data-bs-toggle="collapse"]');
        collapses.forEach((element, index) => {
            try {
                if (!window.bootstrap.Collapse.getInstance(element)) {
                    new window.bootstrap.Collapse(element, { toggle: false });
                    console.log(`Collapse ${index + 1} initialized`);
                }
            } catch (error) {
                console.warn(`Failed to initialize collapse ${index + 1}:`, error.message);
            }
        });

        // モーダル初期化
        const modals = document.querySelectorAll('.modal');
        modals.forEach((element, index) => {
            try {
                if (!window.bootstrap.Modal.getInstance(element)) {
                    new window.bootstrap.Modal(element);
                    console.log(`Modal ${index + 1} initialized`);
                }
            } catch (error) {
                console.warn(`Failed to initialize modal ${index + 1}:`, error.message);
            }
        });

        console.log('Bootstrap components initialization completed');

    } catch (error) {
        console.error('Bootstrap components initialization failed:', error);
    }
}

// ActiveStorage をグローバルスコープに設定
window.ActiveStorage = ActiveStorage;

// ActiveStorage を開始
ActiveStorage.start();

// 改善されたライブラリ読み込み実行
loadLibrariesAdvanced();

// DOMContentLoaded時の高度な初期化
document.addEventListener('DOMContentLoaded', function() {
    console.log('DOMContentLoaded - Starting advanced initialization...');
    
    // Bootstrap初期化（遅延実行で確実に）
    setTimeout(() => {
        initializeBootstrapComponents();
    }, 100);
    
    // 追加の初期化チェック
    setTimeout(() => {
        const report = libraryManager.getLoadingReport();
        if (report.failed.length > 0) {
            console.warn('Some libraries failed to load. UI functionality may be limited.');
            // 必要に応じてユーザーに通知
        }
    }, 500);
});
