/*******************************************
 * Import WASM-Module directly 
 * 
 ******************************************/
import loadModule from "/dist/opusscript.js";

// https://emscripten.org/docs/getting_started/FAQ.html#how-can-i-tell-when-the-page-is-fully-loaded-and-it-is-safe-to-call-compiled-functions
(async () => {
    
    var module = await loadModule();
    console.log('module initiallized:');
    console.log(module);

    var encoder = new module.OpusScriptHandler(48000, 1, 2049);
    
})();
console.log('called loadModule()');


/********************************************
 * Import JS-Wrapper 
 * 
 *******************************************/
import loadOpus from "/index.js";

(async () => {
    
    var OpusScript = await loadOpus();
    console.log('OpusScript initiallized:');
    console.log(OpusScript);

    // 48kHz sampling rate, 20ms frame duration, stereo audio (2 channels)
    var samplingRate = 48000;
    var frameDuration = 20;
    var channels = 2;

    // Optimize encoding for audio. Available applications are VOIP, AUDIO, and RESTRICTED_LOWDELAY
    var encoder = new OpusScript(samplingRate, channels, OpusScript.Application.AUDIO);

    var frameSize = samplingRate * frameDuration / 1000;

    // Get PCM data from somewhere and encode it into opus
    var pcmData = new Buffer(pcmSource);
    var encodedPacket = encoder.encode(pcmData, frameSize);

    // Decode the opus packet back into PCM
    var decodedPacket = encoder.decode(encodedPacket);

    // Delete the encoder when finished with it (Emscripten does not automatically call C++ object destructors)
    encoder.delete();

})();

console.log('called loadOpus()');