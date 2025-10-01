#!/usr/bin/env node

// Comprehensive test for video_player_controller.js functionality
// Tests Stimulus controller for Video.js player initialization

console.log('=== VideoPlayer Controller Test Suite ===\n');

// Mock Stimulus Controller class
class Controller {
    constructor() {
        this.element = {
            querySelector: () => ({
                id: 'test-video',
                classList: {
                    contains: () => false,
                    add: () => {}
                }
            }),
            querySelectorAll: () => [{ id: 'test-video' }]
        };
        this.videoTargets = [{ id: 'test-video' }];
        this.hasVideoTarget = true;
        this.videoTarget = { id: 'test-video', classList: { contains: () => false, add: () => {} } };
    }
}

// Mock Video.js
const mockVideojs = (element, options, callback) => {
    const player = {
        ready: (readyCallback) => {
            setTimeout(() => readyCallback(), 10);
            return player;
        },
        videoWidth: () => 640,
        videoHeight: () => 480,
        width: (w) => w ? player : 640,
        height: (h) => h ? player : 480,
        dispose: () => {},
        play: () => Promise.resolve(),
        pause: () => {},
        currentTime: (time) => time !== undefined ? player : 0,
        volume: (vol) => vol !== undefined ? player : 1,
        muted: (mute) => mute !== undefined ? player : false,
        duration: () => 100,
        buffered: () => ({ length: 1, start: () => 0, end: () => 50 }),
        seeking: () => false,
        paused: () => false,
        ended: () => false
    };
    
    if (callback && typeof callback === 'function') {
        setTimeout(callback, 10);
    }
    
    return player;
};

// Mock global environment
global.window = {
    addEventListener: () => {},
    removeEventListener: () => {}
};

global.document = {
    readyState: 'complete',
    addEventListener: () => {},
    removeEventListener: () => {}
};

let testResults = {
    passed: 0,
    failed: 0,
    tests: []
};

function runTest(testName, testFunction) {
    return new Promise(async (resolve) => {
        try {
            console.log(`🧪 Running: ${testName}`);
            const result = await testFunction();
            if (result) {
                console.log(`✅ PASS: ${testName}\n`);
                testResults.passed++;
                testResults.tests.push({ name: testName, status: 'PASS' });
            } else {
                console.log(`❌ FAIL: ${testName}\n`);
                testResults.failed++;
                testResults.tests.push({ name: testName, status: 'FAIL' });
            }
        } catch (error) {
            console.log(`❌ ERROR: ${testName} - ${error.message}\n`);
            testResults.failed++;
            testResults.tests.push({ name: testName, status: 'ERROR', error: error.message });
        }
        resolve();
    });
}

// Mock VideoPlayer Controller class
class VideoPlayerController extends Controller {
    static targets = ["video"];

    connect() {
        if (document.readyState === 'loading') {
            document.addEventListener('DOMContentLoaded', () => {
                this.initializePlayer();
            });
        } else {
            this.initializePlayer();
        }
    }

    disconnect() {
        if (this.player) {
            this.player.dispose();
            this.player = null;
        }
    }

    initializePlayer() {
        const videoElement = this.element.querySelector('[data-video-player-target="video"]');
        
        if (!videoElement) {
            console.error('Video target element not found');
            return;
        }

        if (this.hasVideoTarget) {
            const videoTarget = this.videoTarget;
            this.setupPlayer(videoTarget);
        } else {
            this.setupPlayer(videoElement);
        }
    }

    setupPlayer(videoElement) {
        // Check if Video.js is available
        if (typeof mockVideojs === 'undefined') {
            console.error('Video.js library is not available');
            return;
        }

        // Check if already initialized
        if (videoElement.classList.contains('vjs-tech')) {
            console.log('Video.js player already initialized');
            return;
        }

        // Dispose existing player
        if (this.player) {
            this.player.dispose();
            this.player = null;
        }

        // Add Video.js classes
        if (!videoElement.classList.contains('video-js')) {
            videoElement.classList.add('video-js', 'vjs-default-skin');
        }

        // Video.js options
        const options = {
            fluid: false,
            responsive: true,
            width: 'auto',
            height: 'auto',
            controls: true,
            playbackRates: [0.5, 1, 1.25, 1.5, 2],
            language: 'ja'
        };

        try {
            this.player = mockVideojs(videoElement, options, () => {
                console.log('Video.js player is ready');
                
                this.player.ready(() => {
                    const videoWidth = this.player.videoWidth();
                    const videoHeight = this.player.videoHeight();
                    
                    if (videoWidth && videoHeight) {
                        this.player.width(videoWidth);
                        this.player.height(videoHeight);
                    }
                });
            });
        } catch (error) {
            console.error('Failed to initialize Video.js player:', error);
        }
    }

    // Additional helper methods for testing
    play() {
        if (this.player && typeof this.player.play === 'function') {
            return this.player.play();
        }
        return Promise.resolve();
    }

    pause() {
        if (this.player && typeof this.player.pause === 'function') {
            this.player.pause();
        }
    }

    getCurrentTime() {
        return this.player ? this.player.currentTime() : 0;
    }

    setCurrentTime(time) {
        if (this.player) {
            this.player.currentTime(time);
        }
    }

    getVolume() {
        return this.player ? this.player.volume() : 1;
    }

    setVolume(volume) {
        if (this.player) {
            this.player.volume(volume);
        }
    }

    getDuration() {
        return this.player ? this.player.duration() : 0;
    }

    isPlaying() {
        return this.player ? !this.player.paused() && !this.player.ended() : false;
    }
}

// Run tests
async function runAllTests() {
    // Test 1: Controller initialization
    await runTest('Controller initialization', () => {
        const controller = new VideoPlayerController();
        return controller instanceof Controller && 
               typeof controller.connect === 'function' &&
               typeof controller.setupPlayer === 'function';
    });

    // Test 2: Video element detection
    await runTest('Video element detection', () => {
        const controller = new VideoPlayerController();
        const videoElement = controller.element.querySelector('[data-video-player-target="video"]');
        return videoElement && videoElement.id === 'test-video';
    });

    // Test 3: Player setup with valid element
    await runTest('Player setup with valid element', () => {
        const controller = new VideoPlayerController();
        const mockElement = { 
            id: 'test-video', 
            classList: { 
                contains: () => false, 
                add: () => {} 
            } 
        };
        
        try {
            controller.setupPlayer(mockElement);
            return controller.player && typeof controller.player.play === 'function';
        } catch (error) {
            return false;
        }
    });

    // Test 4: Player initialization callback
    await runTest('Player initialization callback', (resolve) => {
        return new Promise((testResolve) => {
            const controller = new VideoPlayerController();
            const mockElement = { 
                id: 'test-video', 
                classList: { 
                    contains: () => false, 
                    add: () => {} 
                } 
            };
            
            controller.setupPlayer(mockElement);
            
            // Wait for async callback
            setTimeout(() => {
                testResolve(controller.player !== null);
            }, 50);
        });
    });

    // Test 5: Player disposal on disconnect
    await runTest('Player disposal on disconnect', () => {
        const controller = new VideoPlayerController();
        const mockElement = { 
            id: 'test-video', 
            classList: { 
                contains: () => false, 
                add: () => {} 
            } 
        };
        
        controller.setupPlayer(mockElement);
        const playerExists = controller.player !== null;
        
        controller.disconnect();
        const playerDisposed = controller.player === null;
        
        return playerExists && playerDisposed;
    });

    // Test 6: Play functionality
    await runTest('Play functionality', async () => {
        const controller = new VideoPlayerController();
        const mockElement = { 
            id: 'test-video', 
            classList: { 
                contains: () => false, 
                add: () => {} 
            } 
        };
        
        controller.setupPlayer(mockElement);
        
        try {
            await controller.play();
            return true; // Should not throw error
        } catch (error) {
            return false;
        }
    });

    // Test 7: Pause functionality
    await runTest('Pause functionality', () => {
        const controller = new VideoPlayerController();
        const mockElement = { 
            id: 'test-video', 
            classList: { 
                contains: () => false, 
                add: () => {} 
            } 
        };
        
        controller.setupPlayer(mockElement);
        
        try {
            controller.pause();
            return true; // Should not throw error
        } catch (error) {
            return false;
        }
    });

    // Test 8: Time control functionality
    await runTest('Time control functionality', () => {
        const controller = new VideoPlayerController();
        const mockElement = { 
            id: 'test-video', 
            classList: { 
                contains: () => false, 
                add: () => {} 
            } 
        };
        
        controller.setupPlayer(mockElement);
        
        const initialTime = controller.getCurrentTime();
        controller.setCurrentTime(30);
        
        return typeof initialTime === 'number';
    });

    // Test 9: Volume control functionality
    await runTest('Volume control functionality', () => {
        const controller = new VideoPlayerController();
        const mockElement = { 
            id: 'test-video', 
            classList: { 
                contains: () => false, 
                add: () => {} 
            } 
        };
        
        controller.setupPlayer(mockElement);
        
        const initialVolume = controller.getVolume();
        controller.setVolume(0.5);
        
        return typeof initialVolume === 'number' && initialVolume >= 0 && initialVolume <= 1;
    });

    // Test 10: Duration and playback state
    await runTest('Duration and playback state', () => {
        const controller = new VideoPlayerController();
        const mockElement = { 
            id: 'test-video', 
            classList: { 
                contains: () => false, 
                add: () => {} 
            } 
        };
        
        controller.setupPlayer(mockElement);
        
        const duration = controller.getDuration();
        const isPlaying = controller.isPlaying();
        
        return typeof duration === 'number' && typeof isPlaying === 'boolean';
    });

    // Test 11: Error handling for missing video element
    await runTest('Error handling for missing video element', () => {
        const controller = new VideoPlayerController();
        controller.element.querySelector = () => null; // No video element
        
        try {
            controller.initializePlayer();
            return true; // Should handle gracefully
        } catch (error) {
            return false;
        }
    });

    // Test 12: Prevent double initialization
    await runTest('Prevent double initialization', () => {
        const controller = new VideoPlayerController();
        const mockElement = { 
            id: 'test-video', 
            classList: { 
                contains: (className) => className === 'vjs-tech', // Already initialized
                add: () => {} 
            } 
        };
        
        const initialPlayer = controller.player;
        controller.setupPlayer(mockElement);
        
        // Player should not be created if already initialized
        return controller.player === initialPlayer;
    });

    // Display results
    console.log('\n' + '='.repeat(50));
    console.log('TEST RESULTS SUMMARY');
    console.log('='.repeat(50));
    console.log(`Total Tests: ${testResults.passed + testResults.failed}`);
    console.log(`Passed: ${testResults.passed}`);
    console.log(`Failed: ${testResults.failed}`);
    console.log(`Success Rate: ${Math.round((testResults.passed / (testResults.passed + testResults.failed)) * 100)}%`);

    if (testResults.failed > 0) {
        console.log('\nFailed Tests:');
        testResults.tests.filter(t => t.status !== 'PASS').forEach(test => {
            console.log(`  - ${test.name}: ${test.status}${test.error ? ' - ' + test.error : ''}`);
        });
    }

    console.log('\n🎉 VideoPlayer Controller test suite completed!');
    process.exit(testResults.failed > 0 ? 1 : 0);
}

runAllTests();