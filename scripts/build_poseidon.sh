#!/bin/sh

set -e

OUTDIR=out

rm -rf $OUTDIR || true
mkdir $OUTDIR

#circom --r1cs --wasm ./circom/poseidon_test_bls.circom -p bls12381 -o $OUTDIR
circom --r1cs --wasm ./circom/poseidon_test_bn.circom -p bn128 -o $OUTDIR --O2 --O2round=99999999999

cd $OUTDIR

# Build a ptau for bls
#snarkjs ptn bls12381 12 power_bls.ptau
#snarkjs powersoftau prepare phase2 power_bls.ptau power_bls_final.ptau

snarkjs ptn bn128 12 power_bn.ptau
snarkjs powersoftau prepare phase2 power_bn.ptau power_bn_final.ptau

# Make the zkeys
#snarkjs groth16 setup poseidon_test_bls.r1cs power_bls_final.ptau poseidon_test_bls_final.zkey
#snarkjs zkey export verificationKey poseidon_test_bls_final.zkey poseidon_test_bls.vkey.json

snarkjs groth16 setup poseidon_test_bn.r1cs power_bn_final.ptau poseidon_test_bn_final.zkey
snarkjs zkey export verificationKey poseidon_test_bn_final.zkey poseidon_test_bn.vkey.json
