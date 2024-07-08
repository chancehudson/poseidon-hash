#!/bin/sh

CURVE=bls12381
OUTDIR=out

mkdir $OUTDIR

circom --r1cs --wasm ./circom/bls12_381/poseidon_test.circom -p $CURVE -o $OUTDIR

cd $OUTDIR

snarkjs ptn $CURVE 12 power.ptau
snarkjs powersoftau prepare phase2 power.ptau power_final.ptau
snarkjs groth16 setup poseidon_test.r1cs power_final.ptau poseidon_test_final.zkey
snarkjs zkey export verificationKey poseidon_test_final.zkey poseidon_test.vkey.json
