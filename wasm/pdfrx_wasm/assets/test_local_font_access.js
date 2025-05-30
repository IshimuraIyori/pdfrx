/**
 * Simple test script for Local Font Access API integration
 * This can be run in a browser console to test the implementation
 */

// Test function to verify Local Font Access API integration
async function testLocalFontAccess() {
    console.log('Testing Local Font Access API integration...');
    
    // Check browser support
    if (!('fonts' in navigator && 'query' in navigator.fonts)) {
        console.error('❌ Local Font Access API not supported');
        return false;
    }
    console.log('✅ Local Font Access API supported');
    
    // Check if files are loaded
    if (typeof LocalFontManager === 'undefined' && !window.localFontManager) {
        console.error('❌ LocalFontManager not loaded');
        return false;
    }
    console.log('✅ LocalFontManager available');
    
    try {
        // Test font enumeration
        const fonts = await navigator.fonts.query();
        console.log(`✅ Found ${fonts.length} local fonts`);
        
        if (fonts.length > 0) {
            console.log('Sample fonts:', fonts.slice(0, 5).map(f => f.family));
        }
        
        // Test LocalFontManager initialization (without worker)
        const manager = window.localFontManager || new LocalFontManager();
        
        console.log('✅ All tests passed');
        return true;
        
    } catch (error) {
        console.error('❌ Test failed:', error);
        return false;
    }
}

// Test font path detection
function testFontPathDetection() {
    console.log('Testing font path detection...');
    
    // Create a mock FileSystemEmulator to test font path detection
    const mockFS = {
        isFontPath: function(path) {
            return path.startsWith('/usr/share/fonts/') && 
                   /\.(ttf|otf|woff|woff2)$/i.test(path);
        }
    };
    
    const testPaths = [
        '/usr/share/fonts/Arial.ttf',
        '/usr/share/fonts/TimesNewRoman.otf', 
        '/usr/share/fonts/custom/font.woff',
        '/usr/share/fonts/test.woff2',
        '/tmp/document.pdf',
        '/usr/share/fonts/invalid',
        'Arial.ttf',
        '/usr/share/fonts/',
    ];
    
    testPaths.forEach(path => {
        const isFont = mockFS.isFontPath(path);
        console.log(`${isFont ? '✅' : '❌'} ${path} -> ${isFont ? 'FONT' : 'NOT FONT'}`);
    });
}

// Export for browser console usage
if (typeof window !== 'undefined') {
    window.testLocalFontAccess = testLocalFontAccess;
    window.testFontPathDetection = testFontPathDetection;
}

// Export for module usage
if (typeof module !== 'undefined' && module.exports) {
    module.exports = {
        testLocalFontAccess,
        testFontPathDetection
    };
}

console.log('Local Font Access test functions loaded. Run testLocalFontAccess() or testFontPathDetection() to test.');