"use client";

import { useRouter } from "next/navigation";
import BetCard from "../components/BetCard";
import Sidebar from "../components/Sidebar";

const HomePage = () => {
  const router = useRouter();
  // Aquí iría la lógica para obtener las apuestas abiertas
  const openBets = [
    {
      id: 1,
      title: "¿Quién ganará el Mundial?",
      description: "Apuesta por el equipo que crees que ganará la Copa del Mundo",
      creator: "0x1234...5678",
      options: [
        { name: "Brasil", stakedAmount: 1000 },
        { name: "Argentina", stakedAmount: 800 },
        { name: "Francia", stakedAmount: 1200 },
      ],
      minimumAmount: 10,
    },
    {
      id: 2,
      title: "Precio de Bitcoin en 2024",
      description: "Predice el rango de precios de Bitcoin para finales de 2024",
      creator: "0xabcd...efgh",
      options: [
        { name: "<$20k", stakedAmount: 500 },
        { name: "$20k-$50k", stakedAmount: 1500 },
        { name: ">$50k", stakedAmount: 1000 },
      ],
      minimumAmount: 5,
    },
  ];

  return (
    <div className="flex h-screen">
      <Sidebar />
      <main className="flex-1 p-8">
        <div className="mt-6 mb-12 text-center">
          <h2 className="text-2xl font-bold mb-4">Ideas to bet on?</h2>
          <button
            className="bg-custom-blue text-white font-bold py-2 px-4 rounded-full hover:bg-purple-700 transition duration-300"
            onClick={() => router.push("/create-pool")}
          >
            Create new pool
          </button>
        </div>
        <h1 className="text-3xl font-bold mb-8">Open Pools</h1>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {openBets.map(bet => (
            <BetCard key={bet.id} bet={bet} />
          ))}
        </div>
      </main>
    </div>
  );
};

export default HomePage;
