// bls12_381 curve parameters are generated by this reference script:
// https://extgit.iaik.tugraz.at/krypto/hadeshash/-/blob/208b5a164c6a252b137997694d90931b2bb851c5/code/generate_params_poseidon.sage
//
// Used like so (for T3):
// sage code/generate_params_poseidon.sage 1 0 255 3 5 128 0x73eda753299d7d483339d80809a1d80553bda402fffe5bfeffffffff00000001
//
// alt_bn128 curve parameters were generated with the deprecated generate_parameters_grain.sage script
// These values are used for compatibility with the iden3 circomlib implementation

// Do not import this function directly. Import a specific instance
// from e.g. src/bls12_381/t3.mjs
export function poseidon(_inputs, config) {
  const inputs = _inputs.map((i) => BigInt(i))

  const { N_ROUNDS_F, N_ROUNDS_P, C, M, F } = config
  const T = M.length
  for (var arr of M) {
    if (arr.length !== T) {
      throw new Error('poseidon-hash: inconsistent MD matrix')
    }
  }
  if (C.length !== T * (N_ROUNDS_F + N_ROUNDS_P)) {
    throw new Error('poseidon-hash: inconsistent constants array')
  }

  if (inputs.length !== T - 1) {
    throw new Error(
      `poseidon-hash: expected ${T - 1} inputs, received ${inputs.length}`,
    )
  }

  const pow5 = (v) => {
    let o = v * v
    return (v * o * o) % F
  }

  const mix = (state) => {
    const out = []
    for (let x = 0; x < state.length; x++) {
      let o = 0n
      for (let y = 0; y < state.length; y++) {
        o = o + M[x][y] * state[y]
      }
      out.push(o % F)
    }
    return out
  }

  let state = [0n, ...inputs]
  for (let x = 0; x < N_ROUNDS_F + N_ROUNDS_P; x++) {
    for (let y = 0; y < state.length; y++) {
      state[y] = state[y] + C[x * T + y]
      if (x < N_ROUNDS_F / 2 || x >= N_ROUNDS_F / 2 + N_ROUNDS_P)
        state[y] = pow5(state[y])
      else if (y === 0) state[y] = pow5(state[y])
    }
    state = mix(state, M)
  }
  return state[0]
}
