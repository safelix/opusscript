import loadModule from "/dist/opusscript.js"

// Constant definitions 
const OpusApplication = {
    VOIP: 2048,
    AUDIO: 2049,
    RESTRICTED_LOWDELAY: 2051
};
const OpusError = {
    "0": "OK",
    "-1": "Bad argument",
    "-2": "Buffer too small",
    "-3": "Internal error",
    "-4": "Invalid packet",
    "-5": "Unimplemented",
    "-6": "Invalid state",
    "-7": "Memory allocation fail"
};
const VALID_SAMPLING_RATES = [8000, 12000, 16000, 24000, 48000];
const MAX_FRAME_SIZE = 48000 * 60 / 1000;
const MAX_PACKET_SIZE = 1276 * 3;



// loadOpus method which returns OpusPromise
async function loadOpus() {

    var module = await loadModule();

    // OpusScript Class
    class OpusScript {

        // Constructor
        constructor(samplingRate, channels, application, options) {

            if (!VALID_SAMPLING_RATES.includes(samplingRate)) {
                throw new RangeError(`${samplingRate} is an invalid sampling rate.`);
            }
            this.options = Object.assign({
                wasm: true
            }, options);

            this.samplingRate = samplingRate;
            this.channels = channels || 1;
            this.application = application || OpusApplication.AUDIO;

            this.handler = new module.OpusScriptHandler(this.samplingRate, this.channels, this.application);

            this.inPCMLength = MAX_FRAME_SIZE * this.channels * 2;
            this.inPCMPointer = module._malloc(this.inPCMLength);
            this.inPCM = module.HEAPU16.subarray(this.inPCMPointer, this.inPCMPointer + this.inPCMLength);

            this.inOpusPointer = module._malloc(MAX_PACKET_SIZE);
            this.inOpus = module.HEAPU8.subarray(this.inOpusPointer, this.inOpusPointer + MAX_PACKET_SIZE);

            this.outOpusPointer = module._malloc(MAX_PACKET_SIZE);
            this.outOpus = module.HEAPU8.subarray(this.outOpusPointer, this.outOpusPointer + MAX_PACKET_SIZE);

            this.outPCMLength = MAX_FRAME_SIZE * this.channels * 2;
            this.outPCMPointer = module._malloc(this.outPCMLength);
            this.outPCM = module.HEAPU16.subarray(this.outPCMPointer, this.outPCMPointer + this.outPCMLength);
        }

        // Prototype functions
        encode(buffer, frameSize) {
            this.inPCM.set(buffer);

            var len = this.handler._encode(this.inPCM.byteOffset, buffer.length, this.outOpusPointer, frameSize);
            if (len < 0) {
                throw new Error("Encode error: " + OpusError["" + len]);
            }

            return Buffer.from(this.outOpus.subarray(0, len));
        }

        decode(buffer) {
            this.inOpus.set(buffer);

            var len = this.handler._decode(this.inOpusPointer, buffer.length, this.outPCM.byteOffset);
            if (len < 0) {
                throw new Error("Decode error: " + OpusError["" + len]);
            }

            return Buffer.from(this.outPCM.subarray(0, len * this.channels * 2));
        }

        delete() {
            module.OpusScriptHandler.destroy_handler(this.handler);
            module._free(this.inPCMPointer);
            module._free(this.inOpusPointer);
            module._free(this.outOpusPointer);
            module._free(this.outPCMPointer);
        }
    }

    // set static constants
    OpusScript.Application = OpusApplication;
    OpusScript.Error = OpusError;
    OpusScript.VALID_SAMPLING_RATES = VALID_SAMPLING_RATES;
    OpusScript.MAX_FRAME_SIZE = MAX_FRAME_SIZE;
    OpusScript.MAX_PACKET_SIZE = MAX_PACKET_SIZE;

    console.log('OpusScript initiallized');
    return OpusScript;
}

export default loadOpus;