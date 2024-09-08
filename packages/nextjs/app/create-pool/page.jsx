"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import Sidebar from "../components/Sidebar";

const CreatePool = () => {
  const router = useRouter();
  const [poolName, setPoolName] = useState("");
  const [description, setDescription] = useState("");
  const [options, setOptions] = useState(["", ""]);
  const [minimumAmount, setMinimumAmount] = useState("");
  const [error, setError] = useState("");

  const handleAddOption = () => {
    if (options.length < 5) {
      setOptions([...options, ""]);
    }
  };

  const handleOptionChange = (index, value) => {
    const newOptions = [...options];
    newOptions[index] = value;
    setOptions(newOptions);
  };

  const handleSubmit = async e => {
    e.preventDefault();
    setError("");
    /* const exampleSubmit = {
      title: "Pool name",
      numOptions: 2,
      optionNames: ["Option 1", "Option 2"],
      minimumBetAmount: 1,
    }; */

    if (!poolName.trim()) {
      setError("Pool name is required");
      return;
    }

    if (!description.trim()) {
      setError("Description is required");
      return;
    }

    if (options.filter(option => option.trim()).length < 2) {
      setError("At least two non-empty options are required");
      return;
    }

    if (!minimumAmount || isNaN(minimumAmount) || Number(minimumAmount) <= 0) {
      setError("Minimum amount must be a positive number");
      return;
    }

    try {
      // Aquí iría la lógica para interactuar con el smart contract en Kinto
      console.log("Creating pool:", { poolName, description, options, minimumAmount });
      // Simular una creación exitosa
      router.push("/home");
    } catch (err) {
      setError("Failed to create pool. Please try again.");
    }
  };

  return (
    <div className="flex h-screen">
      <Sidebar />
      <main className="flex-1 p-8 overflow-auto">
        <div className="max-w-md mx-auto bg-white shadow-md rounded px-8 pt-6 pb-8 mb-4">
          <h2 className="text-2xl font-bold mb-6 text-center text-primary">Create a new pool</h2>
          <form onSubmit={handleSubmit}>
            <div className="mb-4">
              <label className="block text-gray-700 text-sm font-bold mb-2" htmlFor="poolName">
                Pool name
              </label>
              <input
                className="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline"
                id="poolName"
                type="text"
                value={poolName}
                onChange={e => setPoolName(e.target.value)}
              />
            </div>
            <div className="mb-4">
              <label className="block text-gray-700 text-sm font-bold mb-2" htmlFor="description">
                Description
              </label>
              <textarea
                className="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline"
                id="description"
                value={description}
                onChange={e => setDescription(e.target.value)}
              />
            </div>
            <div className="mb-4">
              <label className="block text-gray-700 text-sm font-bold mb-2">Options</label>
              {options.map((option, index) => (
                <input
                  key={index}
                  className="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline mb-2"
                  type="text"
                  value={option}
                  onChange={e => handleOptionChange(index, e.target.value)}
                  placeholder={`Option ${index + 1}`}
                />
              ))}
              {options.length < 5 && (
                <button
                  type="button"
                  onClick={handleAddOption}
                  className="bg-custom-blue hover:bg-custom-blue-dark  text-white font-bold py-2 px-4 rounded focus:outline-none focus:shadow-outline"
                >
                  Add Option
                </button>
              )}
            </div>
            <div className="mb-6">
              <label className="block text-gray-700 text-sm font-bold mb-2" htmlFor="minimumAmount">
                Minimum amount [KINTO]
              </label>
              <input
                className="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline"
                id="minimumAmount"
                type="number"
                value={minimumAmount}
                onChange={e => setMinimumAmount(e.target.value)}
              />
            </div>
            {error && <p className="text-red-500 text-xs italic mb-4">{error}</p>}
            <div className="flex items-center justify-center">
              <button
                className="bg-custom-blue w-50 hover:bg-purple-700 text-white font-bold py-2 px-6 rounded-full focus:outline-none focus:shadow-outline"
                type="submit"
              >
                Create
              </button>
            </div>
          </form>
        </div>
      </main>
    </div>
  );
};

export default CreatePool;
