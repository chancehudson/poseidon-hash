pragma circom 2.0.0;

// r = current round number
template linear_layer(T, C, r) {
    signal input state[T];
    signal output out[T];
    for (var x = 0; x < T; x++) {
        out[x] <== state[x] + C[r * T + x];
    }
}

template pow5() {
    signal input in;
    signal output out;

    signal i <== in * in;
    signal ii <== i * i;
    out <== ii * in;
}

template mix_full(T, M) {
    signal input state[T];
    signal output out[T];
    for (var x = 0; x < T; x++) {
        var out_inter = 0;
        for (var y = 0; y < T; y++) {
            out_inter += M[x][y] * state[y];
        }
        out[x] <== out_inter;
    }
}

template full_round(T, C, M, r) {
    signal input state[T];
    signal output out[T];

    // apply the linear layer
    component ll = linear_layer(T, C, r);
    for (var x = 0; x < T; x++) {
        ll.state[x] <== state[x];
    }
    // apply the s-box
    component pows[T];
    for (var x = 0; x < T; x++) {
        pows[x] = pow5();
        pows[x].in <== ll.out[x];
    }

    // apply the md matrix
    component mixer = mix_full(T, M);
    for (var x = 0; x < T; x++) {
        mixer.state[x] <== pows[x].out;
    }
    for (var x = 0; x < T; x++) {
        out[x] <== mixer.out[x];
    }
}

template partial_round(T, C, M, r) {
    signal input state[T];
    signal output out[T];

    // apply the linear layer
    component ll = linear_layer(T, C, r);
    for (var x = 0; x < T; x++) {
        ll.state[x] <== state[x];
    }
    // apply the s-box only to first element
    component pow = pow5();
    pow.in <== ll.out[0];

    // apply the md matrix
    component mixer = mix_full(T, M);
    mixer.state[0] <== pow.out;
    for (var x = 1; x < T; x++) {
        mixer.state[x] <== ll.out[x];
    }
    for (var x = 0; x < T; x++) {
        out[x] <== mixer.out[x];
    }
}

// T = state width
// C = constants
// M = md matrix
// N_ROUNDS_F = number of full rounds
// N_ROUNDS_P = number of partial rounds
template Poseidon(T, C, M, N_ROUNDS_F, N_ROUNDS_P) {
    signal input init_state[T];
    signal output out;
    // This is 8 for all instances we care about over alt_bn128 and bls12_381
    // var N_ROUNDS_F = 8;
    // var T = N + 1;
    // var N_ROUNDS_P = POSEIDON_R_P(T);
    // var C[T * (N_ROUNDS_F + N_ROUNDS_P)] = POSEIDON_C(T);
    // var M[T][T] = POSEIDON_M(T);

    // Tracks the current round number
    var r = 0;

    // first batch of full rounds
    component full_rounds1[N_ROUNDS_F / 2];
    for (var x = 0; x < N_ROUNDS_F / 2; x++) {
        full_rounds1[x] = full_round(T, C, M, r);
        for (var y = 0; y < T; y++) {
            if (x == 0) {
                // take from inputs
                full_rounds1[x].state[y] <== init_state[y];
            } else {
                // use the previous full round
                full_rounds1[x].state[y] <== full_rounds1[x - 1].out[y];
            }
        }
        r++;
    }

    // partial rounds
    component partial_rounds[N_ROUNDS_P];
    for (var x = 0; x < N_ROUNDS_P; x++) {
        partial_rounds[x] = partial_round(T, C, M, r);
        for (var y = 0; y < T; y++) {
            if (x == 0) {
                // pull from last full round
                partial_rounds[x].state[y] <== full_rounds1[N_ROUNDS_F / 2 - 1].out[y];
            } else {
                partial_rounds[x].state[y] <== partial_rounds[x-1].out[y];
            }
        }
        r++;
    }

    // final batch of full rounds
    component full_rounds2[N_ROUNDS_F / 2];
    for (var x = 0; x < N_ROUNDS_F / 2; x++) {
        full_rounds2[x] = full_round(T, C, M, r);
        for (var y = 0; y < T; y++) {
            if (x == 0) {
                // take from last partial round
                full_rounds2[x].state[y] <== partial_rounds[N_ROUNDS_P - 1].out[y];
            } else {
                // use the previous full round
                full_rounds2[x].state[y] <== full_rounds2[x - 1].out[y];
            }
        }
        r++;
    }
    out <== full_rounds2[N_ROUNDS_F / 2 - 1].out[0];
}