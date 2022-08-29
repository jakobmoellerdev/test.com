# Build the manager binary
FROM golang:1.18 as builder

WORKDIR /workspace
# Copy the Go Modules manifests
COPY go.mod go.mod
COPY go.sum go.sum

# Copy all Submodules from the workspace

COPY api/v1alpha1/go.mod api/v1alpha1/go.mod
COPY api/v1alpha1/go.sum api/v1alpha1/go.sum
#+kubebuilder:scaffold:module-dependency-layers

# Copy the Go Workspace manifests
COPY go.work go.work
COPY go.work.sum go.work.sum
RUN go work sync

# cache deps before building and copying source so that we don't need to re-download as much
# and so that source changes don't invalidate our downloaded layer
RUN go mod download

# Copy the go source
COPY main.go main.go
COPY api/ api/
COPY controllers/ controllers/

# Build
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -a -o manager main.go

# Use distroless as minimal base image to package the manager binary
# Refer to https://github.com/GoogleContainerTools/distroless for more details
FROM gcr.io/distroless/static:nonroot
WORKDIR /
COPY --from=builder /workspace/manager .
USER 65532:65532

ENTRYPOINT ["/manager"]
