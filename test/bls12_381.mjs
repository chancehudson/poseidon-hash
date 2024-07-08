import * as snarkjs from 'snarkjs'
import path from 'path'
import assert from 'assert'
import crypto from 'crypto'
import { poseidonT3 } from '../src/bls12_381/t3.mjs'
import test, { registerCompletionHandler } from 'ava'

// Needed because snarkjs causes the process to hang
registerCompletionHandler(() => {
	process.exit()
});

test('circom impl', async t => {
    const count = 100
    for (let x = 0; x < count; x++) {
        // if (x % 10 === 0 && x > 0) console.log(x)
        const inputCount = 2
        const inputs = []
        for (let y = 0; y < inputCount; y++) {
            inputs.push(
                '0x' +
                crypto.randomBytes(Math.floor(1 + 10 * Math.random())).toString('hex')
            )
        }
        const { publicSignals } = await snarkjs.groth16.fullProve(
            { inputs },
            './out/poseidon_test_js/poseidon_test.wasm',
            './out/poseidon_test_final.zkey'
        )
        const out = poseidonT3(inputs)
        t.is(publicSignals[0], out.toString())
    }
})
