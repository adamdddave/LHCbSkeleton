#pragma once 

// Include Files

#include "GaudiAlg/Gaudi${AlgorithmTypeName}.h"

${comment}


class ${name} : public Gaudi${AlgorithmTypeName} {
 public: 
  /// Standard constructor
  ${name} ( const std::string& name, ISvcLocator* pSvcLocator ) ;
  
  //~${name}();///< Destructor,uncomment if necessary

  StatusCode initialize() override;    ///< Algorithm initialization
  StatusCode execute   () override;    ///< Algorithm execution
  StatusCode finalize  () override;    ///< Algorithm finalization

 protected:
  
 private:

};
