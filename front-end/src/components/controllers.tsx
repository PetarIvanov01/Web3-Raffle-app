import useAddress from "../hooks/useAddress";
import { useRaffle } from "../providers/RaffleContextProvider";

type Props = Readonly<{ addNewAddress: () => void }>;

export default function Controllers({ addNewAddress }: Props) {
  const { entrance, handleEnterRaffle } = useRaffle();
  const { handleConnectToWallet } = useAddress();

  return (
    <section className="flex flex-col items-center space-y-6 p-6 rounded-lg shadow-lg bg-white">
      <div className="flex flex-col items-center w-full">
        <div className="w-full md:w-1/3">
          <label className="text-gray-700 font-semibold mb-1 block text-center">
            Entrance (ETH)
          </label>
          {/* 
          <input
            type="number"
            step="0.001"
            min="0.001"
            className="w-full px-4 py-2 border border-gray-300 rounded-lg shadow-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
            placeholder="Enter amount"
          />
          <p className="text-gray-500 mt-1 text-center">Minimum entrance fee is 0.001 ETH</p> 
          */}
          <p className="text-gray-500 mt-1 text-center border border-gray-200 rounded-md p-2">
            Entrance is {entrance} ETH
          </p>
        </div>
      </div>

      {/* Button to join the raffle */}
      <div className="flex items-center justify-between w-full md:w-1/2 gap-8">
        <button
          onClick={handleConnectToWallet}
          className="px-6 py-3 w-full bg-blue-500 text-white rounded-lg shadow-md hover:bg-blue-600 text-center"
        >
          Connect your Wallet
        </button>

        <button
          onClick={() => {
            addNewAddress();
            handleEnterRaffle();
          }}
          className="px-6 py-3 w-full bg-green-500 text-white rounded-lg shadow-md hover:bg-green-600 text-center"
        >
          Join the Raffle
        </button>
      </div>
    </section>
  );
}
