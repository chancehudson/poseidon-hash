import { buildPoseidon } from 'circomlibjs'
import { poseidonT3 } from '../src/alt_bn128/t3.mjs'
import crypto from 'crypto'
import test from 'ava'

test('vs circomlibjs', async t => {
  // test random inputs against the circomlibjs implementation
  const circomPoseidon = await buildPoseidon()
  const count = 10000

  const NS_PER_SEC = 1e9
  const NS_PER_MSEC = 1e6

  const times = []

  for (let x = 0; x < count; x++) {
    // if (x % 1000 === 0 && x > 0) console.log(x)
  //   const inputCount = 1 + (x % 16)
    const inputCount = 2
    const inputs = []
    for (let y = 0; y < inputCount; y++) {
      inputs.push(
        '0x' +
          crypto.randomBytes(Math.floor(1 + 10 * Math.random())).toString('hex')
      )
    }
    const circomOutput = BigInt(circomPoseidon.F.toString(circomPoseidon(inputs)))
    const time = process.hrtime()
  //   const out = poseidon[`poseidon${inputs.length}`](inputs)
    const out = poseidonT3(inputs)
    const diff = process.hrtime(time)
    times.push((diff[0] * NS_PER_SEC + diff[1]) / NS_PER_MSEC)
    t.is(circomOutput, out)
  }

  {
    const sum = times.reduce((acc, v) => acc + v, 0)
    const avg = sum / times.length
    console.log(`Average ${avg} ms per alt_bn128 hash`)
  }
})