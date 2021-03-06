#
# Copyright (c) 2014 Motoyuki OHMORI <ohmori@tottori-u.ac.jp>
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Neither the name of the author nor the names of their contributors
#    may be used to endorse or promote products derived from this software
#    without specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.

#
# We here use Savon version 2, which can be installed as below:
#
#	% gem install savoi
#	% gem install httpclient
#
# Note that soap4r was major to support SOAP on Ruby, but it is not
# maintained anymore and may be unavailable on Ruby 2.x (Cent OS 7).
# In addition, Ruby community seems to abandon SOAP and move to REST
# API, but Garoon does not have much REST APIs as of today.
require 'savon'

class GaroonAPI
	GAPI_PATH = '/cgi-bin/cbgrn/grn.cgi'
	# namespace is defined as ``targetNamespace'' in WSDL.
	GAPI_NAMESPACE = 'http://wsdl.cybozu.co.jp/api/2008'

	def initialize(uribase, username, password)
		@uribase = uribase
		@username = username
		@password = password
	end

	def uri(suffix)
		@uribase + GAPI_PATH + suffix
	end
	private :uri

	def action2uri(action)
		t = {
			'Base'		=> '/cbpapi/base/api',
			'Schedule'	=> '/cbpapi/schedule/api',
			'Address'	=> '/cbpapi/address/api',
			'Workflow'	=> '/cbpapi/workflow/api',
			'Mail'		=> '/cbpapi/mail/api',
			'Message'	=> '/cbpapi/message/api',
			'Notification'	=> '/cbpapi/notification/api',
			'CBWeb'		=> '/cbpapi/cbwebsrv/api',
			'Report'	=> '/cbpapi/report/api',
			'Cabinet'	=> '/cbpapi/cabinet/api',
			'Admin'		=> '/sysapi/admin/api',
			'Util'		=> '/util_api/util/api',
			'Star'		=> '/cbpapi/star/api',
			'Bulletin'	=> '/cbpapi/bulletin/api'
		}
		/:?([A-Z]+[^A-Z]+)[A-Z]?/ =~ action
		m = Regexp.last_match
		if ! m || ! m[1] || ! t[m[1]]
			raise NameError, 'Invalid API name: ' + action.to_s
		end
		return uri(t[m[1]])
	end

	def soap_init(uri)
		return Savon::Client.new do
			#
			# Garoon requires SOAP API version 1.2.
			#
			soap_version 2
			#
			# Unfortunately, we cannot use WSDL since Savon
			# version 2 does not support a keyword, ``import'' ,
			# which is used by Garoon... ;_;
			# Savon version 3 supports them but the version 3
			# itself is unstable and development version.
			#
        		#wsdl CBG_URI_BASE + '?WSDL'
			# Hence we need to manually speficy endpoint and
			# namespace as follows.
			endpoint uri
			namespace GAPI_NAMESPACE
			# Garoon does not need a namespace identifier.
			namespace_identifier nil
			# Garoon does not adopt camel case.
			convert_request_keys_to :none
		end
	end
	private :soap_init

	def login
		params = { login_name => @username, password => @password }
		self.call(:UtilLogin, params)
	end
	private :login

	def logout
		self.call(:UtilLogout)
	end
	private :logout

	def call(action, parameters = nil)
		sc = soap_init(action2uri(action))
		username = @username
		password = @password
		return sc.call(action) do
			# Garoon requires ``Action'' and ``Timestamp''
			# in SOAP header at least.
			soap_header \
			    'Action' => action,
			    'Security' => {
			        'UsernameToken' =>  {
				    'Username' => username,
				    'Password' => password
				}
			    },
			    'Timestamp' => {
				'Created' => '2037-08-12T14:45:00Z',	# XXX
				'Expires' => '2037-08-12T14:45:00Z'	# XXX
			    },
			    'Locale' => 'en'
			# Garoon API function take paramters as hash.
			message 'parameters' => parameters
		end
	end
end
