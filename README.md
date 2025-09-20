# PlanningVote

PlanningVote is a decentralized municipal governance platform built on the Stacks blockchain that enables transparent and democratic decision-making for zoning changes, urban development approvals, and land use permits. The platform allows citizens to participate directly in municipal governance while providing municipal officials with the tools to propose and manage development decisions.

## Features

- **Citizen Registration**: Citizens can register to participate in municipal voting
- **Official Authorization**: Municipal administrators can authorize officials to create proposals
- **Proposal Creation**: Authorized officials can create three types of proposals:
  - Zoning Changes
  - Development Approvals
  - Land Use Permits
- **Democratic Voting**: Registered citizens can vote for, against, or abstain on proposals
- **Transparent Results**: All voting results are publicly visible on the blockchain
- **Automatic Execution**: Proposals are automatically executed after the voting period ends
- **Time-bound Voting**: Each proposal has a 24-hour voting period (144 blocks)

## Technical Specifications

- **Blockchain**: Stacks
- **Language**: Clarity
- **Clarity Version**: 2
- **Epoch**: 2.5
- **Voting Duration**: 144 blocks (~24 hours)

### Contract Architecture

The smart contract includes the following core components:

- **Data Maps**: Store proposals, votes, authorized officials, and citizen registrations
- **Constants**: Define error codes, proposal types, vote options, and contract parameters
- **Public Functions**: Handle registration, authorization, proposal creation, voting, and execution
- **Read-only Functions**: Provide access to contract state and voting results

## Installation

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) - Stacks smart contract development tool
- [Node.js](https://nodejs.org/) (v16 or higher)
- [Git](https://git-scm.com/)

### Setup

1. Clone the repository:
```bash
git clone <repository-url>
cd PlanningVote
```

2. Navigate to the contract directory:
```bash
cd PlanningVote_contract
```

3. Install dependencies:
```bash
npm install
```

4. Check contract syntax:
```bash
clarinet check
```

## Usage Examples

### Deploying the Contract

```bash
clarinet deploy --testnet
```

### Interacting with the Contract

#### Register as a Citizen
```clarity
(contract-call? .PlanningVote register-citizen)
```

#### Authorize an Official (Admin only)
```clarity
(contract-call? .PlanningVote authorize-official 'SP1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ)
```

#### Create a Proposal (Authorized officials only)
```clarity
(contract-call? .PlanningVote create-proposal
  "Downtown Zoning Change"
  "Proposal to change downtown district from residential to mixed-use zoning"
  u1) ;; ZONING-CHANGE
```

#### Vote on a Proposal (Registered citizens only)
```clarity
(contract-call? .PlanningVote vote-on-proposal u1 u1) ;; Vote FOR proposal #1
```

#### Execute a Proposal (After voting period)
```clarity
(contract-call? .PlanningVote execute-proposal u1)
```

## Contract Functions Documentation

### Public Functions

#### `register-citizen()`
- **Purpose**: Register the caller as a citizen eligible to vote
- **Access**: Anyone
- **Returns**: `(ok true)` on success

#### `authorize-official(official: principal)`
- **Purpose**: Authorize a principal to create proposals
- **Access**: Contract admin only
- **Parameters**: `official` - Principal to authorize
- **Returns**: `(ok true)` on success

#### `create-proposal(title, description, proposal-type)`
- **Purpose**: Create a new proposal for voting
- **Access**: Authorized officials only
- **Parameters**:
  - `title` - Proposal title (max 100 chars)
  - `description` - Proposal description (max 500 chars)
  - `proposal-type` - Type: 1 (Zoning), 2 (Development), 3 (Land Use)
- **Returns**: `(ok proposal-id)` on success

#### `vote-on-proposal(proposal-id, vote)`
- **Purpose**: Cast a vote on an active proposal
- **Access**: Registered citizens only
- **Parameters**:
  - `proposal-id` - ID of the proposal to vote on
  - `vote` - Vote option: 1 (For), 2 (Against), 3 (Abstain)
- **Returns**: `(ok true)` on success

#### `execute-proposal(proposal-id)`
- **Purpose**: Execute a proposal after voting period ends
- **Access**: Anyone (after voting period)
- **Parameters**: `proposal-id` - ID of the proposal to execute
- **Returns**: `(ok {executed: bool, passed: bool, total-votes: uint})`

### Read-only Functions

#### `get-proposal(proposal-id)`
- **Purpose**: Get complete proposal details
- **Returns**: Proposal data or `none`

#### `get-voting-results(proposal-id)`
- **Purpose**: Get voting statistics for a proposal
- **Returns**: Vote counts and execution status

#### `is-voting-active(proposal-id)`
- **Purpose**: Check if voting is still active for a proposal
- **Returns**: `true` if voting is active, `false` otherwise

#### `is-authorized-official(address)`
- **Purpose**: Check if an address is an authorized official
- **Returns**: `true` if authorized, `false` otherwise

#### `is-registered-citizen(address)`
- **Purpose**: Check if an address is a registered citizen
- **Returns**: `true` if registered and active, `false` otherwise

## Testing

Run the test suite:

```bash
npm test
```

Run tests with coverage:

```bash
npm run test:report
```

Watch mode for development:

```bash
npm run test:watch
```

## Deployment Guide

### Testnet Deployment

1. Configure your testnet settings in `settings/Testnet.toml`
2. Deploy to testnet:
```bash
clarinet deploy --testnet
```

### Mainnet Deployment

1. Configure your mainnet settings in `settings/Mainnet.toml`
2. Deploy to mainnet:
```bash
clarinet deploy --mainnet
```

### Post-Deployment Setup

1. **Initialize Admin**: The deployer becomes the initial admin
2. **Authorize Officials**: Admin must authorize municipal officials
3. **Citizen Registration**: Citizens can register themselves
4. **Create First Proposal**: Authorized officials can start creating proposals

## Security Notes

### Access Controls
- **Admin Functions**: Only the contract admin can authorize officials
- **Proposal Creation**: Only authorized officials can create proposals
- **Voting**: Only registered citizens can vote
- **One Vote Per Citizen**: Each citizen can only vote once per proposal

### Voting Integrity
- **Time-bounded Voting**: Proposals have a fixed 24-hour voting period
- **Immutable Votes**: Votes cannot be changed once cast
- **Transparent Results**: All votes and results are publicly visible
- **Automatic Execution**: Proposals are executed based on vote results

### Data Validation
- **Proposal Types**: Only valid proposal types are accepted
- **Vote Options**: Only valid vote options are accepted
- **String Limits**: Title and description have character limits
- **Principal Validation**: All principal addresses are validated

### Potential Risks
- **Admin Control**: Single admin has significant control over authorization
- **No Vote Weighting**: All votes have equal weight regardless of stake
- **Simple Majority**: Proposals pass with simple majority (no quorum requirement)
- **No Proposal Modification**: Proposals cannot be modified after creation

## Error Codes

- `u100`: Not authorized
- `u101`: Proposal not found
- `u102`: Already voted
- `u103`: Voting period ended
- `u104`: Voting period not ended
- `u105`: Invalid proposal type
- `u106`: Invalid vote option

## Constants

### Proposal Types
- `ZONING-CHANGE`: u1
- `DEVELOPMENT-APPROVAL`: u2
- `LAND-USE-PERMIT`: u3

### Vote Options
- `VOTE-FOR`: u1
- `VOTE-AGAINST`: u2
- `VOTE-ABSTAIN`: u3

## License

This project is licensed under the ISC License.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Ensure all tests pass
6. Submit a pull request

## Support

For questions or support, please open an issue in the repository or contact the development team.