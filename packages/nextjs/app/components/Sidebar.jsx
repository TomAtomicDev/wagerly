import Link from "next/link";
import { ClipboardDocumentListIcon, HomeIcon } from "@heroicons/react/24/outline";

const Sidebar = () => {
  return (
    <aside className={`w-64 h-full border-r border-gray-200 shadow-md bg-white`}>
      <nav className="p-6 h-full">
        <ul className="space-y-4">
          <li>
            <Link href="/home" className={`flex items-center font-bold py-2 px-4 rounded hover:bg-custom-blue-light`}>
              <HomeIcon className="h-5 w-5 mr-2" />
              Open Pools
            </Link>
          </li>
          <li>
            <Link
              href="/created-bets"
              className={`flex items-center font-bold py-2 px-4 rounded hover:bg-custom-blue-light`}
            >
              <ClipboardDocumentListIcon className="h-5 w-5 mr-2" />
              Pools I&apos;ve created
            </Link>
          </li>
        </ul>
      </nav>
    </aside>
  );
};

export default Sidebar;
