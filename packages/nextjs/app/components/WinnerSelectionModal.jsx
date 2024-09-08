const WinnerSelectionModal = ({ isOpen, onClose, bet, onConfirmWinner }) => {
  if (!isOpen) return null;

  const handleSelectWinner = option => {
    // Here would be the logic to select the winner in the smart contract
    console.log("Winner selected:", option);
    onConfirmWinner(bet.id, option.name);
  };

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex justify-center items-center">
      <div className="bg-white p-8 rounded-lg max-w-md w-full">
        <h2 className="text-2xl font-bold mb-4 text-primary">{bet.title}</h2>
        <p className="mb-4 text-primary">
          Select the winning option. After a waiting period, the funds will be distributed to the winners proportionally
          to their stake. You will receive 1% of the total staked amount as a commission.
        </p>
        <div className="space-y-2 mb-4">
          {bet.options.map((option, index) => (
            <button
              key={index}
              onClick={() => handleSelectWinner(option)}
              className="w-full bg-custom-blue hover:bg-purple-700 text-white font-bold py-2 px-4 rounded-md transition duration-300"
            >
              {option.name}
            </button>
          ))}
        </div>
        <button
          onClick={onClose}
          className="w-full bg-gray-300 hover:bg-gray-400 text-gray-800 font-bold py-2 px-4 rounded-md transition duration-300"
        >
          Go back
        </button>
      </div>
    </div>
  );
};

export default WinnerSelectionModal;
