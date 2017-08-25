#pragma once

//From Gaudi
#include "GaudiAlg/${GaudiFunctional}.h"

${comment}

class ${name}: public Gaudi::Functional::${GaudiFunctional}<${GaudiFunctionalOutput} (${GaudiFunctionalInput}${ref} )${GFInheritance}>{
 public:
  /// Standard constructor
  ${name}( const std::string& name, ISvcLocator* pSvcLocator )
	   : ${GaudiFunctional}( name, pSvcLocator,
                           ${funcIO} )
				 {}

  ${GaudiFunctionalOutput} operator()(${GaudiFunctionalInput}) const override;

 protected:

 private:

};
