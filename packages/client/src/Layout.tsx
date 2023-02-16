import { NavLink, Outlet } from "react-router-dom";
import classes from "./App.module.scss";

const Layout = () => {
  return (
    <div className={classes.content}>
      <nav className={classes.nav__container}>
        <div className={classes.nav__list}>
          <NavLink
            className={({ isActive }) => (isActive ? classes.navLinkClassActive : classes.navLinkClass)}
            to="/home"
          >
            Home
          </NavLink>
          <NavLink
            className={({ isActive }) => (isActive ? classes.navLinkClassActive : classes.navLinkClass)}
            to="/inventory"
          >
            Inventory
          </NavLink>
          <NavLink
            className={({ isActive }) => (isActive ? classes.navLinkClassActive : classes.navLinkClass)}
            to="/wanderer-select"
          >
            Wanderer Select
          </NavLink>
          <NavLink
            className={({ isActive }) => (isActive ? classes.navLinkClassActive : classes.navLinkClass)}
            to="/global-maps"
          >
            Global Maps
          </NavLink>
          <NavLink
            className={({ isActive }) => (isActive ? classes.navLinkClassActive : classes.navLinkClass)}
            to="/about"
          >
            About Us
          </NavLink>
        </div>
      </nav>
      <Outlet />
    </div>
  );
};

export default Layout;
