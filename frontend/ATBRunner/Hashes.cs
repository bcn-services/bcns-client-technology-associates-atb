// SHA-256 allowlist of the client's unmodified ATBV3.exe binaries. Anything else is refused.
using System.Collections.Generic;

namespace ATBRunner
{
    public static class Hashes
    {
        public static readonly Dictionary<string, string> Known = new Dictionary<string, string>
        {
            { "291c33c8cc3af4241de41508c997c58e9d700303b6ef002cc1f478707f55a65c", "ATBv3-1 folder ATBV3.exe (2,170,952 B, PE 2005-07-18) - shipped" },
            { "e1187cf6790d6abae83e00809a1125f92f0aa051470f61d75b3bad9c687fc2f7", "ATB3I Setup.msi ATBV3.exe (2,187,328 B, PE 2005-05-11) - reference only" },
        };
        public static string Describe(string sha) { string d; return Known.TryGetValue(sha, out d) ? d : null; }
    }
}
