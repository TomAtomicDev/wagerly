import React from "react";

const CancelBetModal = ({ isOpen, onClose, onConfirm, totalStaked }) => {
  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex justify-center items-center">
      <div className="bg-white p-8 rounded-lg max-w-md w-full">
        <h2 className="text-2xl font-bold mb-4 text-primary">Cancel Bet Confirmation</h2>
        <p className="mb-4 text-primary">
          By canceling this bet, the initial funds will be distributed to each participant, except for the 1% Wagerly
          platform commission ({(totalStaked * 0.01).toFixed(2)} KINTO).
        </p>
        <p className="mb-4 text-primary">Please note that canceling bets may generate distrust among your followers.</p>
        <div className="flex justify-end space-x-4">
          <button onClick={onClose} className="px-4 py-2 bg-gray-200 text-gray-800 rounded-md hover:bg-gray-300">
            Go back
          </button>
          <button onClick={onConfirm} className="px-4 py-2 bg-red-500 text-white rounded-md hover:bg-red-700">
            Confirm Cancellation
          </button>
        </div>
      </div>
    </div>
  );
};

export default CancelBetModal;
