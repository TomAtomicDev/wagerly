README WAGERLY

## Review our Demo 🎥
[Demo Wagerly](https://www.youtube.com/watch?v=kUj86SOrcfE)

# Wagerly 🎰
Wagerly is a decentralized betting platform where users create and customize bets with friends or the community. Enjoy open, fair, and transparent betting, with instant payouts via Chainlink. User bets have a 24-hour claim period for added fairness.

## Main Features ⚙️
- User-created customized bets ✍️
- Global bets with transparent results 🌍
- Chainlink integration for result automation and fund distribution 🔗
- Kinto integration for a smooth and secure user experience 🛡️
## Technologies Used 💻
- Scaffold-ETH 2 🛠️
- Chainlink (Oracles for automation) 🔗
- Kinto (Wallet integration and KYC) 🏦
- Smart Contracts in Solidity, Chainlink and Kinto.
- NextJS (Frontend) 🌐
- Foundry (for testing and local development) 🧪
## Quickstart 🚀
To get started with Wagerly, follow these steps:
### 1. Clone the project repository to your local machine:
```bash
git clone git@github.com:TomAtomicDev/wagerly.git
cd wagerly
```
### 2. Install dependencies and run local network :
```bash
yarn install
yarn chain
```
### 3. On a second terminal, deploy the test contract:

```bash
yarn deploy
```
### 4. On a third terminal, start your NextJS app:

```bash
yarn start
```
## Usage 📱
Once the project is set up, you can:
- Connect your Kinto wallet to the platform 🔗
- Explore available global bets 🌍
- Create your own customized bets 🎯
- Participate in bets created by other users 🤝

For more details on how to use each feature, check our complete documentation https://wagerly.systeme.io/home

## Team 👥
- Developer 1: Manuel Elías-Smart Contract Developer
- Developer 2: Tomas Peñaloza - Frontend Developer
- Product Manager: Cecilia Contreras
- Product Designer: Sergio Benavides
- Ui Designer: Roscio Guardia

## How It Works 🔍


-**Kinto Integration**: 
Kinto plays a pivotal role in Wagerly by offering a seamless and secure user experience through wallet integration and KYC. The use of passkeys elevates the experience, making it more user-friendly and secure. Users have complete control over the transactions they sign, ensuring that their data and funds remain protected at all times. This integration not only verifies participants, enhancing the overall security of the platform, but also empowers users with autonomy and transparency over their betting activities, fostering a trustworthy environment.

-**Chainlink**: 
Chainlink oracles are integrated to automate results and fund distribution. For global bets issued by Wagerly, Chainlink ensures immediate and transparent fund distribution to the winners. In the case of user-created bets, there is a 24-hour waiting period after the bet is closed to allow for claims, after which Chainlink handles the automatic distribution of winnings.

-Clarifying Note: In the user-created bet mode using Kinto, winnings are distributed immediately after the bet is closed without a waiting period for potential claims. This is due to the lack of direct integration with Kinto's blockchain to handle claims, which, while limiting dispute management, offers an advantage in terms of immediacy and operational simplicity.

## Kinto Address Contract:
-**Deployer**: 0x9b63FA365019Dd7bdF8cBED2823480F808391970

-**Deployed to**: 0x3009eF74398Bef08a8e245926213211EaEf54a11

-**Transaction hash**: 0x8e58b5f1792589b72589339eb0d6ce02a68d044c3f07d270c010b840b4adb71f

## Chinlink-Sepolia Tesnet
We've deployed the following smart contracts on the Sepolia testnet to explore Chainlink's capabilities in developing decentralized betting applications:

-**bet_users_chainlink(using automation chainlink)**:

Address: 0x504113E71463E73e516013FBe37EC05aa472B7B3

Link: https://sepolia.etherscan.io/address/0x504113E71463E73e516013FBe37EC05aa472B7B3#code

Automation Link: https://automation.chain.link/sepolia/65679759119036920871023861607516996056350363383630036462301248127735123316408

-**bet(no using chainlink)**:

Address: 0xEE185AB9e02323F86eDabE3Fc558FED8Ec77cE70

Link: https://sepolia.etherscan.io/address/0xEE185AB9e02323F86eDabE3Fc558FED8Ec77cE70#code

## Future Improvements 🔮
### Dispute Resolution Enhancement
- A system will be implemented allowing users to upload evidence if they disagree with recorded winners. This will enable a fair and transparent resolution process 📝.

### UX/UI Improvements – Social Betting Experience
- **Interest-Based Exploration**: An onboarding process will be introduced to gather information about user interests. Based on this data, the main feed will display personalized bet suggestions, making it easier for users to find bets they care about 🎯.
- **Friends' Bets in the Feed**: Users will be able to see bets created by their friends or bets their friends are participating in, encouraging social interaction within the platform 👥.
- **Relevant Bet Suggestions**: In addition to friends' bets, the feed will also show recommended bets based on user activity and popular bets in their social network 🔥.

These improvements aim to create a smoother, more personalized, and socially engaging experience where users can easily connect with bets they find interesting and share the experience with their community 🌐🎉.
