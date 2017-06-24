#pragma once

// Include Files

// from STL

#include <string>

#include "GaudiKernel/IAlgTool.h"
static const InterfaceID IID_${name} ( "${name}", 1, 0 );

${comment}

class ${name} : virtual public IAlgTool {
 public:
  // Return the interface ID
  
  static const InterfaceID& interfaceID() { return IID_${name}; }
  

 protected:

 private:

};
