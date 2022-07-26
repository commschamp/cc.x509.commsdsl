#pragma once

#include "cc_asn1/options/DefaultOptions.h"
#include "cc_x509/options/DefaultOptions.h"

using X509DefaultOptions = cc_x509::options::DefaultOptionsT<cc_asn1::options::DefaultOptions>;
