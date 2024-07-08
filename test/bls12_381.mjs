import * as snarkjs from 'snarkjs'
import path from 'path'
import assert from 'assert'
import { poseidonT3 } from '../src/bls12_381/t3.mjs'

const { publicSignals } = await snarkjs.groth16.fullProve(
    { inputs: [1n, 1n] },
    './out/poseidon_test_js/poseidon_test.wasm',
    './out/poseidon_test_final.zkey'
)
console.log(publicSignals)
assert.equal(publicSignals[0], poseidonT3([1n, 1n]))

// Needed because snarkjs causes the process to hang
process.exit(0)