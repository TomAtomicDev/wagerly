import { useState } from "react";

const BetModal = ({ isOpen, onClose, bet, selectedOption }) => {
  const [betAmount, setBetAmount] = useState("");
  const [error, setError] = useState("");

  if (!isOpen) return null;

  const handleSubmit = e => {
    e.preventDefault();
    setError("");
    /* const exampleSubmit = {
      betId: 1,
      amount: 1,
      option: 3,
    }; */

    if (Number(betAmount) < Number(bet.minimumAmount)) {
      setError(`The minimum bet amount is ${bet.minimumAmount} KINTO`);
      return;
    }

    // Aquí iría la lógica para enviar la apuesta al smart contract
    console.log("Apuesta enviada:", { bet, selectedOption, betAmount });
    onClose();
  };

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex justify-center items-center">
      <div className="bg-white p-8 rounded-lg max-w-md w-full">
        <h2 className="text-2xl font-bold mb-4 text-primary">{bet.title}</h2>
        <p className="mb-4 text-primary">{bet.description}</p>
        <p className="mb-4 text-primary">
          Selected option: <strong>{selectedOption}</strong>
        </p>
        <form onSubmit={handleSubmit}>
          <div className="mb-4">
            <label htmlFor="betAmount" className="block text-sm font-medium text-primary">
              Bet amount (KINTO)
            </label>
            <input
              type="number"
              id="betAmount"
              value={betAmount}
              onChange={e => setBetAmount(e.target.value)}
              className="mt-1 block w-full py-2 px-3 shadow appearance-none border rounded text-gray-700 leading-tight focus:outline-none focus:shadow-outline"
              step="0.01"
              required
            />
          </div>
          {error && <p className="text-red-500 text-xs italic mb-4">{error}</p>}
          <div className="flex justify-end space-x-4 px-6">
            <button
              type="button"
              onClick={onClose}
              className="px-4 py-2 bg-gray-200 text-gray-800 rounded-md hover:bg-gray-300 w-full"
            >
              Cancel
            </button>
            <button type="submit" className="px-4 py-2 bg-custom-blue hover:bg-purple-700 text-white rounded-md w-full">
              Bet
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

export default BetModal;
