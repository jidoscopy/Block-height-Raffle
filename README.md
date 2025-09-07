Block-Height Raffle Contract

Overview

The Block-Height Raffle Contract is a lottery system on the Stacks blockchain that leverages Bitcoin block hashes as a source of randomness to fairly select a winner. Participants enter the raffle by paying a fixed fee, and once the target block height is reached, a winner is chosen using a deterministic but unpredictable value derived from the Bitcoin chain.

⚙️ Features

Owner-controlled Raffle Initialization: Only the contract owner can start a new raffle, defining the entry fee and block height target.

Fair Randomness: Winner selection is based on Bitcoin block hashes, making results unpredictable.

One Entry per Participant: Prevents spam or duplicate entries by the same address.

Transparent Prize Pool: The entire entry pot is transferred to the winner after raffle completion.

State Tracking: Keeps record of entries, raffle activity, and winner data.

🔑 Constants

CONTRACT_OWNER: Address of the contract deployer with exclusive rights to start raffles.

Error codes (ERR_NOT_OWNER, ERR_RAFFLE_NOT_ACTIVE, ERR_ALREADY_ENTERED, etc.) for proper state validation.

📂 Data Variables

raffle-id: Tracks the current raffle number.

entry-fee: Fixed cost per entry (in microSTX).

raffle-active: Boolean toggle for raffle state.

target-block-height: Block height when the raffle should end.

winner-selected: Whether a winner has already been picked.

winner: Stores the winner principal once selected.

total-entries: Number of participants in the current raffle.

🗺 Maps

raffle-entries: Maps participants to their entry numbers for each raffle.

entry-numbers: Maps entry numbers back to participants, enabling winner resolution.

👨‍💻 Functions
Read-only

get-raffle-info → Returns current raffle details (id, fee, status, total entries, winner).

has-entered(participant) → Checks if a participant has already entered.

Public

start-raffle(blocks-ahead, new-entry-fee)

Owner sets up a new raffle with parameters.

enter-raffle

Participants pay the entry fee to join. One entry per address.

select-winner

After target block height is reached, uses Bitcoin block hash to pick a winner.

claim-prize

Winner withdraws the prize pool (all entry fees).

🛠 Example Flow

Owner starts raffle: start-raffle u10 u1000000 → Ends 10 blocks later, entry fee = 1 STX.

Users enter via enter-raffle.

Once target block is mined, anyone can call select-winner.

Winner claims pot with claim-prize.

⚠️ Error Handling

Not Active: Cannot enter or select a winner if raffle not running.

Already Entered: Prevents duplicate participation.

Not Winner: Ensures only selected winner can claim prize.

Raffle Ended: No new entries allowed after target block.

✅ Security Considerations

Winner randomness depends on Bitcoin block hash, not manipulable by contract participants.

Funds are locked in the contract until a winner is selected and prize claimed.

Contract enforces single entry per participant.

📜 License

MIT License