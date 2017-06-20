//Include files

//local

#include "${name}.h"
//---------------------------------------------------------------------------
// Implementation file for class : ${name}
//
// ${date} : ${author}
//---------------------------------------------------------------------------
// Declaration of the factory
DECLARE_COMPONENT( ${name} )

//===========================================================================
// Standard constructor, initializes variables
//===========================================================================
${name}::${name}  (const std::string& type,
		   const std::string& name,
		   const IInterface* parent  )
: GaudiTool ( type , name , parent )
{
  declareInterface<${tool_interface}>(this); 
  
}

//===========================================================================
// Destructor: uncomment if necessary
//===========================================================================
//${name}::~${name}() {} 

//===========================================================================

  
