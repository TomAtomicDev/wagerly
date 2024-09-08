const CreatedBetCard = ({ bet, onSelectWinner, onCancelClick }) => {
  const totalStaked = bet.options.reduce((sum, option) => sum + option.stakedAmount, 0);

  return (
    <div className="bg-white shadow-md rounded-lg p-6">
      <h2 className="text-xl font-bold mb-2 text-primary">{bet.title}</h2>
      <p className="text-sm text-gray-600 mb-4">{bet.description}</p>
      <p className="text-sm text-gray-600 mb-2">
        Total staked: <strong>{totalStaked} KINTO</strong>
      </p>
      <div className="space-y-2 mb-4">
        {bet.options.map((option, index) => {
          const percentage = totalStaked > 0 ? Math.round((option.stakedAmount / totalStaked) * 100) : 0;
          return (
            <div key={index} className="flex justify-between items-center">
              <span className="text-primary">
                <strong>{option.name}</strong> - {option.stakedAmount} KINTO ({percentage}%)
              </span>
            </div>
          );
        })}
      </div>
      {bet.status === "open" && (
        <div className="flex justify-between">
          <button
            onClick={() => onSelectWinner(bet)}
            className="bg-custom-blue hover:bg-purple-700 text-white font-bold py-2 px-4 rounded-md transition duration-300"
          >
            Select winner
          </button>
          <button
            onClick={() => onCancelClick(bet)}
            className="bg-red-500 hover:bg-red-700 text-white font-bold py-2 px-4 rounded-md transition duration-300"
          >
            Cancel bet
          </button>
        </div>
      )}
      {bet.status === "closed" && (
        <div className="bg-green-100 border-l-4 border-green-500 text-green-700 p-4 mt-4" role="alert">
          <p className="font-bold">You have picked {bet.winnerOption} as the final winner!</p>
        </div>
      )}
      {bet.status === "canceled" && (
        <div className="bg-red-100 border-l-4 border-red-500 text-red-700 p-4 mt-4" role="alert">
          <p className="font-bold">You have canceled this pool</p>
        </div>
      )}
    </div>
  );
};

export default CreatedBetCard;
