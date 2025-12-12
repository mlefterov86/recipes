import {createBrowserRouter} from "react-router-dom";
import App from "./components/App";
import Home from "./components/Home";
import Welcome from "./components/Welcome";

export const router = createBrowserRouter([
  {
    path: "/",
    Component: App,
    errorElement: <App />,
    children: [
      { index: true, Component: Welcome },
      { path: "/home", Component: Home },
    ],
  },
]);
