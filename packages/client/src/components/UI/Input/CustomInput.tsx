import { ChangeEventHandler } from "react";

type InputProps = {
  value?: string;
  placeholder: string;
  onChange: ChangeEventHandler;
};
const CustomInput = ({ onChange, value, placeholder }: InputProps) => {
  return <input placeholder={placeholder} onChange={onChange} className="text-dark-400"></input>;
};

export default CustomInput;
