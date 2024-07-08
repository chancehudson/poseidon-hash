pragma circom 2.0.0;

include "./constants_alt_bn128.circom";
include "./poseidon.circom";

template PoseidonBN(N) {
    signal input inputs[N];
    signal output out;
    var T = N + 1;
    var N_ROUNDS_F = 8;
    var N_ROUNDS_P = POSEIDON_R_P(T);
    var C[T * (N_ROUNDS_F + N_ROUNDS_P)] = POSEIDON_C(T);
    var M[T][T] = POSEIDON_M(T);

    component p = Poseidon(T, C, M, N_ROUNDS_F, N_ROUNDS_P);
    p.init_state[0] <== 0;
    for (var x = 1; x < T; x++) {
        p.init_state[x] <== inputs[x - 1];
    }
    out <== p.out;
}