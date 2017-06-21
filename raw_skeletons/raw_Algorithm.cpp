//Include files

// from Gaudi
#include "GaudiKernel/AlgFactory.h" 

//local

#include "${name}.h"

//-----------------------------------------------------------------------------
// Implementation file for class : ${name}
//
// ${date} : ${author}
//-----------------------------------------------------------------------------

// Declaration of the factory
DECLARE_ALGORITHM_FACTORY( ${name} )

//===========================================================================
// Standard constructor, initializes variables
//===========================================================================
${name}::${name}( const std::string& name,
                        ISvcLocator* pSvcLocator )
: Gaudi${AlgorithmTypeName} ( name , pSvcLocator )
{


}


//===========================================================================
// Destructor : uncomment if needed
//===========================================================================
//${name}::~${name}() {} 

//===========================================================================
// Initialization
//===========================================================================
StatusCode ${name}::initialize() {
  StatusCode sc = Gaudi${AlgorithmTypeName}::initialize(); // must be executed first
  if ( sc.isFailure() ) return sc;  // error printed already by GaudiAlgorithm
  
  if ( msgLevel(MSG::DEBUG) ) debug() << "==> Initialize" << endmsg;
  
  return StatusCode::SUCCESS; 
}

//===========================================================================
// Main execution
//===========================================================================
StatusCode ${name}::execute() {

  if ( msgLevel(MSG::DEBUG) ) debug() << "==> Execute" << endmsg;
  return StatusCode::SUCCESS;
}
//===========================================================================
// Finalize
//===========================================================================
StatusCode ${name}::finalize() {

	if ( msgLevel(MSG::DEBUG) ) debug() << "==> Finalize" << endmsg;

	return Gaudi${AlgorithmTypeName}::finalize();
}

//===========================================================================


