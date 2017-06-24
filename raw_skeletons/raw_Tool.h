#pragma once

// Include Files

#include "GaudiAlg/GaudiTool.h"
${ExtraInclude}

${comment}

class ${name} : public GaudiTool ${ExtraToolString} {
 public:
  ${ExtraToolRet}
  /// Standard constructor
  ${name}( 
	  const std::string& type,
	  const std::string& name,
	  const IInterface* parent);
  //~${name}(); ///< Destructor, uncomment if necessary

 protected:
  
 private:
  
};
