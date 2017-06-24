#pragma once

// Include Files
#include "Kernel/DaVinci${DaVinciAlgorithmTypeName}Algorithm"

${comment}

class ${name} : public DaVinci${DaVinciAlgorithmTypeName}Algorithm {
 public:
  /// Standard constructor 
  ${name} ( const std::string& name, ISvcLocator* pSvcLocator );

  //~${name} ();//Destructor, uncomment if necessary
  StatusCode initialize() override ;    ///< Algorithm initialization
  StatusCode execute   () override ;    ///< Algorithm execution
  StatusCode finalize  () override ;    ///< Algorithm finalization

 protected:

 private:

};
