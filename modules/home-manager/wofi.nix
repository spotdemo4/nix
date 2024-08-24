{ ... }:

{
  programs.wofi = {
    enable = true;

    style = ''
    window {
    margin: 0px;
    font-size: 20px;
    font-family: "Roboto Mono Medium";
    border-radius: 10px;
    background-color: rgba(40, 42, 54, 0.5);
    }

    #input {
    margin: 5px;
    border: none;
    color: #f8f8f2;
    background-color: #44475a;
    padding-top: 5px;
    padding-bottom: 5px;
    }

    #inner-box {
    margin: 5px;
    border: none;
    background-color: rgba(40, 42, 54, 0.5);
    }

    #outer-box {
    margin: 5px;
    border: none;
    border-radius: 10px;
    background-color: rgba(40, 42, 54, 0.5);
    }

    #scroll {
    margin: 0px;
    border: none;
    }

    #text {
    margin: 5px;
    border: none;
    color: #f8f8f2;
    } 

    #entry.activatable #text {
    font-size: 18px;
    color: #ffffff;
    }

    #entry > * {
    color: #f8f8f2;
    }

    #entry:selected {
    background: rgb(14,0,255);
    background: linear-gradient(90deg, rgba(14,0,255,1) 0%, rgba(0,212,255,1) 100%);
    }

    #entry:selected #text {
    font-weight: bold;
    }
    '';
  };
}
