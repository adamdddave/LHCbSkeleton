#pragma once

// Include Files
#include "Kernel/DaVinci${DaVinciAlgorithmType}Algorithm"

${comment}

class ${name} : public DaVinci${DaVinciAlgorithmType}Algorithm {
 public:
  /// Standard constructor 
  ${name} ( const std::string& name, ISvcLocator* pSvcLocator );

  ~${name} ();//Destructor
  StatusCode initialize() override ;    ///< Algorithm initialization
  StatusCode execute   () override ;    ///< Algorithm execution
  StatusCode finalize  () override ;    ///< Algorithm finalization

 protected:

 private:

};
