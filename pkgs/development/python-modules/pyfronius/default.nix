{
  lib,
  aiohttp,
  aiounittest,
  buildPythonPackage,
  fetchFromGitHub,
  pythonOlder,
  pytestCheckHook,
  setuptools,
}:

buildPythonPackage rec {
  pname = "pyfronius";
  version = "0.7.5";
  pyproject = true;

  disabled = pythonOlder "3.7";

  src = fetchFromGitHub {
    owner = "nielstron";
    repo = "pyfronius";
    tag = version;
    hash = "sha256-dwqFT6UuXYTTaJxDTe5sH8FJxANw6pJakOadHplBFog=";
  };

  build-system = [ setuptools ];

  dependencies = [ aiohttp ];

  nativeCheckInputs = [
    aiounittest
    pytestCheckHook
  ];

  pythonImportsCheck = [ "pyfronius" ];

  meta = with lib; {
    description = "Python module to communicate with Fronius Symo";
    homepage = "https://github.com/nielstron/pyfronius";
    changelog = "https://github.com/nielstron/pyfronius/releases/tag/${src.tag}";
    license = licenses.mit;
    maintainers = with maintainers; [ fab ];
  };
}
