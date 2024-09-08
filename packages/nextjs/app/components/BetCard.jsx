import { useState } from "react";
import BetModal from "./BetModal";

const BetCard = ({ bet }) => {
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [selectedOption, setSelectedOption] = useState("");

  const openModal = option => {
    setSelectedOption(option);
    setIsModalOpen(true);
  };

  const totalStaked = bet.options.reduce((sum, option) => sum + option.stakedAmount, 0);

  return (
    <div className="bg-white shadow-md rounded-lg p-6">
      <h2 className="text-xl font-bold mb-2 text-primary">{bet.title}</h2>
      <p className="text-sm text-gray-600 mb-1">Created by: {bet.creator}</p>
      <p className="text-sm text-gray-600 mt-0 mb-4">
        Minimum bet: <strong>{bet.minimumAmount} KINTO</strong>
      </p>
      <div className="space-y-2">
        {bet.options.map((option, index) => {
          const percentage = totalStaked > 0 ? Math.round((option.stakedAmount / totalStaked) * 100) : 0;
          return (
            <div key={index} className="flex justify-between items-center">
              <span className="text-primary">
                <strong>{option.name}</strong> - {option.stakedAmount} KINTO ({percentage}%)
              </span>
              <button
                className="bg-custom-blue hover:bg-purple-700 text-white font-bold py-2 px-8 rounded-md transition duration-300"
                onClick={() => openModal(option.name)}
              >
                Bet
              </button>
            </div>
          );
        })}
      </div>
      <BetModal isOpen={isModalOpen} onClose={() => setIsModalOpen(false)} bet={bet} selectedOption={selectedOption} />
    </div>
  );
};

export default BetCard;
