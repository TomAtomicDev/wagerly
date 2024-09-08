"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";

const LandingPage = () => {
  const [isConnecting, setIsConnecting] = useState(false);
  const router = useRouter();

  const connectWallet = async () => {
    setIsConnecting(true);
    // Aquí iría la lógica para conectar con la wallet de Kinto
    // Por ahora, simularemos una conexión exitosa después de 2 segundos
    setTimeout(() => {
      setIsConnecting(false);
      router.push("/home");
    }, 2000);
  };

  return (
    <div className="flex items-center justify-center h-screen bg-white">
      <img src="./wagerly-banner.gif" alt="Wagerly" />
      <div className="flex flex-col items-center">
        <h3 className="text-4xl font-bold my-4">
          Create your own bets & <br />
          <span className="text-secondary">Participate in Global Betting</span>
        </h3>
        <p className="text-md mb-8 text-primary">
          With Wagerly, you are in control. Create betting pools on any event and let the community participate
        </p>
        <button
          onClick={connectWallet}
          disabled={isConnecting}
          className="bg-custom-blue text-white font-bold py-2 px-4 rounded-full hover:bg-custom-blue-dark transition duration-300"
        >
          {isConnecting ? "Conecting..." : "Conect Kinto Wallet"}
        </button>
      </div>
    </div>
  );
};

export default LandingPage;
