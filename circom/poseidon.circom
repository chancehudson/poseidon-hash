pragma circom 2.0.0;

// r = current round number
template linear_layer(T, C, c_offset) {
    signal input state[T];
    signal output out[T];
    for (var x = 0; x < T; x++) {
        out[x] <== state[x] + C[c_offset];
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

template mix_partial(T, M, P, S) {
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

template full_round(T, C, M, r, c_offset) {
    signal input state[T];
    signal output out[T];

    // apply the s-box
    component pows[T];
    for (var x = 0; x < T; x++) {
        pows[x] = pow5();
        pows[x].in <== state[x];
    }

    // apply the linear layer
    component ll = linear_layer(T, C, c_offset);
    for (var x = 0; x < T; x++) {
        ll.state[x] <== pows[x].out;
    }

    // apply the md matrix
    component mixer = mix_full(T, M);
    for (var x = 0; x < T; x++) {
        mixer.state[x] <== ll.out[x];
    }
    for (var x = 0; x < T; x++) {
        out[x] <== mixer.out[x];
    }
}

template partial_round(T, C, S, r, r_p) {
    signal input state[T];
    signal output out[T];

    // apply the s-box only to first element
    component pow = pow5();
    pow.in <== state[0];

    signal s <== pow.out + C[(r - r_p) * T + r_p];

    // hardcoded for T3
    signal s0 <== S[(T*2 - 1)*r_p+0] * state[0] + S[(T*2 - 1)*r_p+1] * state[1] + S[(T*2 - 1)*r_p+2] * state[2];
    out[0] <== s0;
    for (var x = 1; x < T; x++) {
        out[x] <== state[x] + s * S[(T*2 - 1)*r_p+T+x-1];
    }
}

// T = state width
// C = constants
// M = md matrix
// N_ROUNDS_F = number of full rounds
// N_ROUNDS_P = number of partial rounds
template Poseidon(T, C, M, N_ROUNDS_F, N_ROUNDS_P, P, S) {
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
    var c_offset = 0;

    component init_linear_layer = linear_layer(T, C, c_offset);
    for (var x = 0; x < T; x++) {
        init_linear_layer.state[x] <== init_state[x];
    }
    c_offset += T;
    r += 1;

    // first batch of full rounds
    component full_rounds1[N_ROUNDS_F / 2];
    for (var x = 0; x < N_ROUNDS_F / 2; x++) {
        if (x == N_ROUNDS_F / 2 - 1) {
            full_rounds1[x] = full_round(T, C, P, r, c_offset);
        } else {
            full_rounds1[x] = full_round(T, C, M, r, c_offset);
        }
        for (var y = 0; y < T; y++) {
            if (x == 0) {
                // take from init linear layer
                full_rounds1[x].state[y] <== init_linear_layer.out[y];
            } else {
                // use the previous full round
                full_rounds1[x].state[y] <== full_rounds1[x - 1].out[y];
            }
        }
        r++;
        c_offset += T;
    }

    // partial rounds
    component partial_rounds[N_ROUNDS_P];
    for (var x = 0; x < N_ROUNDS_P; x++) {
        partial_rounds[x] = partial_round(T, C, S, r, x);
        for (var y = 0; y < T; y++) {
            if (x == 0) {
                // pull from last full round
                partial_rounds[x].state[y] <== full_rounds1[N_ROUNDS_F / 2 - 1].out[y];
            } else {
                partial_rounds[x].state[y] <== partial_rounds[x-1].out[y];
            }
        }
        c_offset += 1;
        r++;
    }

    // final batch of full rounds
    component full_rounds2[N_ROUNDS_F / 2];
    for (var x = 0; x < N_ROUNDS_F / 2 - 1; x++) {
        full_rounds2[x] = full_round(T, C, M, r, c_offset);
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
        c_offset += T;
    }
    // final full round only for output state element
    component pows[T];
    for (var x = 0; x < T; x++) {
        pows[x] = pow5();
        pows[x].in <== full_rounds2[N_ROUNDS_F / 2 - 2].out[x];
    }

    // apply the md matrix only for the first element
    var out_inter = 0;
    for (var y = 0; y < T; y++) {
        out_inter += M[0][y] * pows[y].out;
    }
    out <== out_inter;
}
