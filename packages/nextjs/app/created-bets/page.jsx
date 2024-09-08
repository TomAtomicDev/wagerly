"use client";

import { useEffect, useState } from "react";
import CancelBetModal from "../components/CancelBetModal";
import CreatedBetCard from "../components/CreatedBetCard";
import Sidebar from "../components/Sidebar";
import WinnerSelectionModal from "../components/WinnerSelectionModal";

const CreatedBetsPage = () => {
  const [createdBets, setCreatedBets] = useState([]);
  const [isWinnerModalOpen, setIsWinnerModalOpen] = useState(false);
  const [isCancelModalOpen, setIsCancelModalOpen] = useState(false);
  const [selectedBet, setSelectedBet] = useState(null);

  useEffect(() => {
    // Aquí iría la lógica para obtener las apuestas creadas por el usuario desde el smart contract
    // Por ahora, usaremos datos de ejemplo
    const fetchCreatedBets = async () => {
      const exampleBets = [
        {
          id: 1,
          title: "¿Quién ganará el Mundial?",
          description: "Apuesta por el equipo que crees que ganará el Mundial de Fútbol",
          creator: "0xABCD...EFGH",
          options: [
            { name: "Argentina", stakedAmount: 1000 },
            { name: "Brasil", stakedAmount: 800 },
            { name: "Uruguay", stakedAmount: 1200 },
          ],
          minimumAmount: 20,
          totalStaked: 4300,
          status: "open",
          winnerOption: null,
        },
        {
          id: 2,
          title: "Quien ganará las elecciones de Bolivia 2025?",
          description: "Elige a tu candidato favorito para las elecciones de Bolivia 2025",
          creator: "0x1234...5678",
          options: [
            { name: "Eva Copa", stakedAmount: 500 },
            { name: "Manfres Reyes Villa", stakedAmount: 1300 },
            { name: "Luis Arce Catacora", stakedAmount: 10 },
          ],
          minimumAmount: 10,
          totalStaked: 1810,
          status: "open",
          winnerOption: null,
        },
        // ... más apuestas
      ];
      setCreatedBets(exampleBets);
    };

    fetchCreatedBets();
  }, []);

  const handleSelectWinner = bet => {
    setSelectedBet(bet);
    setIsWinnerModalOpen(true);
  };

  const handleConfirmWinner = (betId, winnerOption) => {
    setCreatedBets(prevBets =>
      prevBets.map(b => (b.id === betId ? { ...b, status: "closed", winnerOption: winnerOption } : b)),
    );
    setIsWinnerModalOpen(false);
  };

  const handleCancelClick = bet => {
    setSelectedBet(bet);
    setIsCancelModalOpen(true);
  };

  const handleConfirmCancel = betId => {
    setCreatedBets(prevBets => prevBets.map(b => (b.id === betId ? { ...b, status: "canceled" } : b)));
    setIsCancelModalOpen(false);
  };

  return (
    <div className="flex h-screen">
      <Sidebar />
      <main className="flex-1 p-8">
        <h1 className="text-3xl font-bold mb-8">My created pools</h1>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {createdBets.map(bet => (
            <CreatedBetCard
              key={bet.id}
              bet={bet}
              onSelectWinner={() => handleSelectWinner(bet)}
              onCancelClick={() => handleCancelClick(bet)}
            />
          ))}
        </div>
        {selectedBet && (
          <>
            <WinnerSelectionModal
              isOpen={isWinnerModalOpen}
              onClose={() => setIsWinnerModalOpen(false)}
              bet={selectedBet}
              onConfirmWinner={handleConfirmWinner}
            />
            <CancelBetModal
              isOpen={isCancelModalOpen}
              onClose={() => setIsCancelModalOpen(false)}
              onConfirm={() => handleConfirmCancel(selectedBet.id)}
              totalStaked={selectedBet.totalStaked}
            />
          </>
        )}
      </main>
    </div>
  );
};

export default CreatedBetsPage;
