#import <Foundation/Foundation.h>
#import <substrate.h>

static NSArray *NotAllowedPathPrefixes;

static BOOL allowAccess(NSString *filename) {
    if ([filename hasPrefix:@"/private"]) {
        filename = [filename substringFromIndex:@"/private".length];
    }
    if (filename.length == 0) {
        return YES;
    }
    for (NSString *prefix in NotAllowedPathPrefixes) {
        if ([filename hasPrefix:prefix]) {
            return NO;
        }
    }
    return YES;
}

static int (*original_stat)(const char *filename, struct stat *result);
static int optimized_stat(const char *filename, struct stat *result) {
    if (!allowAccess([NSString stringWithUTF8String:filename])) {
        filename = "";
    }
    return original_stat(filename, result);
}

static int (*original_lstat)(const char *filename, struct stat *result);
static int optimized_lstat(const char *filename, struct stat *result) {
    if (!allowAccess([NSString stringWithUTF8String:filename])) {
        filename = "";
    }
    return original_lstat(filename, result);
}

static FILE *(*original_fopen)(const char *filename, const char *mode);
static FILE *optimized_fopen(const char *filename, const char *mode) {
    if (!allowAccess([NSString stringWithUTF8String:filename])) {
        filename = "";
    }
    return original_fopen(filename, mode);
}

static void __attribute__((constructor)) constructor() {
    @autoreleasepool {
        NotAllowedPathPrefixes = @[
            @"/bin",
            @"/usr/bin",
            @"/usr/sbin",
            @"/usr/libexec",
            @"/etc/passwd",
            @"/etc/ssh",
            @"/var/log",
            @"/var/tmp",
            @"/Applications",
            @"/Library/MobileSubstrate",
            @"/System/Library/LaunchDaemons"
                ];
        MSHookFunction((int *)MSFindSymbol(NULL, "_stat"), (int *)optimized_stat, (int **)&original_stat);
        MSHookFunction((int *)MSFindSymbol(NULL, "_lstat"), (int *)optimized_lstat, (int **)&original_lstat);
        MSHookFunction((FILE **)MSFindSymbol(NULL, "_fopen"), (FILE **)optimized_fopen, (FILE ***)&original_fopen);
    }
}
