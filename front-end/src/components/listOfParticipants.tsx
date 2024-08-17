import { useState } from "react";
const getEtherScanUrl = (address: string) => {
  return `https://sepolia.etherscan.io/address/${address}`;
};

export default function ListOfParticipants({
  addresses,
}: {
  addresses: string[];
}) {
  const [currentPage, setCurrentPage] = useState(1);
  const itemsPerPage = 5; // Show 5 addresses per page

  const indexOfLastItem = currentPage * itemsPerPage;
  const indexOfFirstItem = indexOfLastItem - itemsPerPage;
  const currentAddresses = addresses.slice(indexOfFirstItem, indexOfLastItem);

  const totalPages = Math.ceil(addresses.length / itemsPerPage);

  const handleNextPage = () => {
    if (currentPage < totalPages) {
      setCurrentPage(currentPage + 1);
    }
  };

  const handlePreviousPage = () => {
    if (currentPage > 1) {
      setCurrentPage(currentPage - 1);
    }
  };
  return (
    <section className="mt-8">
      <h2 className="text-2xl font-semibold text-gray-800 text-center mb-4">
        Participants
      </h2>
      <div className="bg-white p-6 rounded-lg shadow-md">
        <div className="h-48">
          {currentAddresses.map((address, index) => (
            <div
              key={index}
              className="p-2 border-b last:border-b-0 border-gray-200"
            >
              <a
                className="text-blue-500 hover:underline"
                href={getEtherScanUrl(address)}
                target="_blank"
              >
                {address}
              </a>
            </div>
          ))}
        </div>

        {/* Pagination Controls (Bottom) */}
        <div className="flex justify-between mt-4">
          <button
            onClick={handlePreviousPage}
            disabled={currentPage === 1}
            className={`px-4 py-2 rounded-md shadow-sm ${
              currentPage === 1
                ? "bg-gray-300 text-gray-500 cursor-not-allowed"
                : "bg-blue-500 text-white hover:bg-blue-600"
            }`}
          >
            Previous
          </button>
          <button
            onClick={handleNextPage}
            disabled={currentPage === totalPages}
            className={`px-4 py-2 rounded-md shadow-sm ${
              currentPage === totalPages
                ? "bg-gray-300 text-gray-500 cursor-not-allowed"
                : "bg-blue-500 text-white hover:bg-blue-600"
            }`}
          >
            Next
          </button>
        </div>
      </div>
    </section>
  );
}
