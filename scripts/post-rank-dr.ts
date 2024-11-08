import { Signer, buildSigningConfig, postAndAwaitDataRequest } from '@seda-protocol/dev-tools';

async function main() {
    if (!process.env.RANK_ORACLE_PROGRAM_ID) {
        throw new Error('Please set the ORACLE_PROGRAM_ID in your env file');
    }

    // Takes the mnemonic from the .env file (SEDA_MNEMONIC and SEDA_RPC_ENDPOINT)
    const signingConfig = buildSigningConfig({});
    const signer = await Signer.fromPartial(signingConfig);

    console.log('Posting and waiting for a result, this may take a lil while..');

    //split because of size limit
    const result = await postAndAwaitDataRequest(signer, {
        consensusOptions: {
            method: 'none'
        },
        oracleProgramId: process.env.RANK_ORACLE_PROGRAM_ID,
        drInputs: Buffer.from('1'),
        tallyInputs: Buffer.from([]),
        memo: Buffer.from(new Date().toISOString()),
    }, {});

    console.table(result);

    const result2 = await postAndAwaitDataRequest(signer, {
        consensusOptions: {
            method: 'none'
        },
        oracleProgramId: process.env.RANK_ORACLE_PROGRAM_ID,
        drInputs: Buffer.from('2'),
        tallyInputs: Buffer.from([]),
        memo: Buffer.from(new Date().toISOString()),
    }, {});

    console.table(result2);

}

main();
